module Common
  module Core
    module Ca
      module User

        def self.included(base)
          base.class_eval do
            has_one :access, :foreign_key => :viewer_id
            has_many :persons, :through => :access

            validates_uniqueness_of _(:username), :case_sensitive => false, :message => "(username) has already been taken"

            validates_no_association_data :access, :persons

            def username=(val)
              # don't let username= be set to viewer_userID
              # TODO why is this here? -AR
              if RAILS_ENV == 'test'
                self.viewer_userID = val
              end
            end

            def password() '' end
            def password=(val) '' end

            def created_at=(v) end

            def person
              @person ||= persons.first if !persons.empty?
            end

            # set person in-ememory, not fully implemented to stick to db.
            # useful to keep the in-memory just_created flag
            def person=(v) 
              @person = v
            end

            def to_liquid() {} end
          end

          base.extend UserClassMethods
        end

        def login_callback
          person.sync_cim_hrdb
          viewer_isActive = true
        end

        def human_is_active()
          return self.is_active == 0 ? "no" : "yes"
        end

        def in_access_group(*ids)

          return false unless ids

          id_array = []
          ids.each { |id| id_array << id.to_i if id.to_i }

          ::AccountadminVieweraccessgroup.all(:first, :conditions => {:viewer_id => self.id, :accessgroup_id => id_array}).empty? ? false : true
        end

        
        module UserClassMethods

          def find_or_create_from_cas(ticket)
            # Look for a user with this guid
            receipt = ticket.response
            atts = receipt.extra_attributes
            guid = att_from_receipt(atts, 'ssoGuid')
            first_name = att_from_receipt(atts, 'firstName')
            last_name = att_from_receipt(atts, 'lastName')
            email = receipt.user
            u = find_or_create_from_guid_or_email(guid, email, first_name, last_name)
           
            # update last login and email in a way that won't break the rest of the login if it
            # doesn't work
            begin
              u.viewer_lastLogin = Time.now
              u.viewer_userID = receipt.user
              u.save!
            rescue
              noop = true # apparently rcov needs a statement to mark this block as covered
            end

            return u
          end

          def find_or_create_from_guid_or_email(guid, email, first_name, last_name, secure = true)
            if guid
              u = ::User.find(:first, :conditions => _(:guid, :user) + " = '#{guid}'")
            else
              guid ||= "GUID" if RAILS_ENV == "test"
              u = nil
            end

            # if we have a user by this method, great! update the email address if it doesn't match
            if u
              unless u.person
                p = ::Person.create_new_cim_hrdb_person first_name, last_name, email
                p.setup_and_create_access(u)
              end
              u.person.email = email
            else
              # If we didn't find a user with the guid, do it by email address and stamp the guid
              if secure
                u = ::User.find(:first, :conditions => {
                  _(:username, :user) => [ email.upcase, email.downcase ],
                  _(:guid, :user) => "" # check for hijacking
                })
              else
                u = ::User.find(:first, :conditions => {
                  _(:username, :user) => [ email.upcase, email.downcase ],
                })
              end

              unless u
                # try by person email
                p = ::Person.find(:first, :conditions => "#{_(:email, :person)} = '#{email.upcase}' or #{_(:email, :person)} = '#{email.downcase}'")
                #p = Person.find(:all).select{|p| p.email == reciept.user.upcase || p.email == reciept.user.downcase}.first
                u = p.user if p
                if secure
                  u = nil unless u && u.guid = "" # check for hijacking
                end
              end

              if u && secure
                u.viewer_userID = email        # force longer usernames by using their email
                                               # instead of silly short usernames; this is ok because
                                               # we don't support the accountadmin_viewer logins anymore
                u.guid = guid
                u.save!
              elsif u.nil?
                # If we still don't have a user in SSM, we need to create one.
                #u = User.create!(:username => receipt.user, :guid => guid)
                u = ::Person.create_new_cim_hrdb_account guid, first_name,
                  last_name, email
              end
            end

            return u
          end

          def search(search, page, per_page)
            if search then
              ::User.paginate(:page => page,
                              :per_page => per_page,
                              :joins => :accountadmin_accountgroup,
                              :conditions => ["#{_(:username, :user)} like ? " +
                                              "or #{_(:guid, :user)} like ? " +
                                              "or #{_(:viewer_id, :user)} like ? " +
                                              "or #{_(:english_value, :accountadmin_accountgroup)} like ? ",
                                              "%#{search}%", "%#{search}%", "%#{search}%", "%#{search}%"])
            else
              nil
            end
          end

        end

      end
    end
  end
end
