module Common
  module Core
    module Ca
      module Person

        def self.included(base)
          base.class_eval do
            #  doesnt_implement_attributes :major => '', :minor => '', :url => '', :staff_notes => '', :updated_at => '', :updated_by => ''

            has_many :cim_hrdb_admins, :class_name => 'CimHrdbAdmin'

            has_one :access
            has_many :users, :through => :access

            has_many :assignments
            has_many :assignmentstatuses, :through => :assignments

            has_one :emerg
            belongs_to :gender_, :class_name => "Gender", :foreign_key => :gender_id

            has_one :cim_hrdb_staff
            has_many :cim_hrdb_person_years
            has_many :cim_hrdb_school_years, :through => :cim_hrdb_person_years, :source => :school_year

            has_one :person_extra_ref, :class_name => 'PersonExtra'

            belongs_to :title, :foreign_key => :title_id

            belongs_to :loc_state, :foreign_key => "person_local_province_id", :class_name => "State"
            belongs_to :loc_country, :foreign_key => "person_local_country_id", :class_name => "Country"
            belongs_to :perm_state, :foreign_key => :province_id, :class_name => "State"
            belongs_to :perm_country, :foreign_key => "country_id", :class_name => "Country"

            def update_addresses() end # noop since address info is in person
            def created_at=(v) end # noop since it would have set the id to the timestamp
            def user
              @user ||= users.first
            end
            def user=(v) @user = v end # fake setting the user, so that just_created memory-only flag will stick
            def person_extra()
              @person_extra ||= person_extra_ref || ::PersonExtra.new(:person_id => id)
            end
            def major() person_extra.major end
            def major=(val) person_extra.major = val end
            def minor() person_extra.minor end
            def minor=(val) person_extra.minor = val end
            def curr_dorm() person_extra.curr_dorm end
            def curr_dorm=(val) person_extra.curr_dorm = val end
            def perm_dorm() person_extra.perm_dorm end
            def perm_dorm=(val) person_extra.perm_dorm = val end
            def url() person_extra.url end
            def url=(val) person_extra.url = val end
            def staff_notes() person_extra.staff_notes end
            def staff_notes=(val) person_extra.staff_notes = val end
            def updated_at() person_extra.updated_at end
            def updated_at=(val) person_extra.updated_at = val end
            def updated_by() person_extra.updated_by end
            def updated_by=(val) person_extra.updated_by = val end
            def save_emerg?() @save_emerg end
            def save_emerg=(val) @save_emerg = val end
            def initialize_addresses() end
            def primary_campus() most_recent_involvement.try(:campus) end

            after_update { |record|
              record.person_extra.save!
              if record.save_emerg?
                record.get_emerg.save!
                record.save_emerg = false
              end

            }

            def gender
              gender_.try(:gender_desc)
            end

            def birth_date() get_emerg ? get_emerg.emerg_birthdate : nil; end
            def birth_date=(v) 
              return if new_record?
              @save_emerg = true
              get_emerg.emerg_birthdate = v
            end

            def created_by=(v) end # don't bother

            def gender=(val)
              case val
              when US_MALE_GENDER_ID.to_i, US_MALE_GENDER_ID.to_s, 'M'
                self.gender_id = CIM_MALE_GENDER_ID
              when US_FEMALE_GENDER_ID.to_i, US_FEMALE_GENDER_ID.to_s, 'F'
                self.gender_id = CIM_FEMALE_GENDER_ID
              end
            end

            def gender_us_id
              case gender_id
              when CIM_MALE_GENDER_ID
                US_MALE_GENDER_ID.to_s
              when CIM_FEMALE_GENDER_ID
                US_FEMALE_GENDER_ID.to_s
              end
            end

            def current_address() id ? ::CimHrdbCurrentAddress.find(id) : ::CimHrdbCurrentAddress.new  end
            def permanent_address() id ? ::CimHrdbPermanentAddress.find(id) : ::CimHrdbPermanentAddress.new end
            def emergency_address() nil end

            def graduation_date() cim_hrdb_person_years.first.try(:grad_date) end

            def campus(o = {}) hrdb_student_campus(o) end

            def self.find_exact(person, address)
              # check based on username first
              user = ::User.find(:first, :conditions => ["#{_(:username, :user)} = ?", address.email])
              if user && user.person.nil?
                # If we have an orphaned user record, might as well use it...
                person.setup_and_create_access(user)
                person.save(false)
                p = person
              else
                p = user.person if user
              end
              unless p
                p = ::Person.find(:first, :conditions => ["#{_(:email, :person)} = ?", address.email])
                unless p.user
                  p.create_user_and_access_only("", p.email)
                end
              end
              return p
            end

            @@current_student_assignment_status_id = @@unknown_assignment_status_id = nil

            def hrdb_student_campus(options = {})

              # look for current assignment first
              if @@current_student_assignment_status_id.nil?
                @@current_student_assignment_status_id = ::Assignmentstatus.find_by_assignmentstatus_desc("Current Student").try(:id)
              end

              if @@current_student_assignment_status_id
                if options[:search_arrays]
                  c = assignments.detect{ |a| a.assignmentstatus_id == @@current_student_assignment_status_id }
                else
                  c = assignments.find_by_assignmentstatus_id @@current_student_assignment_status_id, :include => :campus
                end

                return c.campus if c
              end

              # look for unknown assignment
              if @@unknown_assignment_status_id.nil?
                @@unknown_assignment_status_id = ::Assignmentstatus.find_by_assignmentstatus_desc("Unknown Status").try(:id)
              end

              if @@unknown_assignment_status_id
                if options[:search_arrays]
                  u = assignments.detect{ |u| u.assignmentstatus_id == @@unknown_assignment_status_id }
                else
                  u = assignments.find_by_assignmentstatus_id @@unknown_assignment_status_id, :include => :campus
                end

                return u.campus if u
              end

              return nil
            end

            def is_staff_somewhere?(skip_hrdb_check = false)
              super() || (!skip_hrdb_check && is_hrdb_staff?)
            end
            
            ######### address helpers
            # TODO: some of these should use CmtGeo

            def gender_short
              if self.gender_id == 1 then 'M' elsif self.gender_id == 2 then 'F' else '?' end
            end

            def legal_first_name
              self.person_legal_fname
            end

            def legal_last_name
              self.person_legal_lname
            end

            def permanent_phone
              self.person_phone
            end

            def permanent_address_line1
              self.person_addr
            end

            def permanent_address_line2
              ""
            end

            def permanent_city
              self.person_city
            end

            def permanent_state
              permanent_province
            end

            def permanent_province
              if perm_state then perm_state.province_shortDesc else 'no perm province set' end
            end

            def permanent_country
              if perm_country then perm_country.country_shortDesc else 'no perm country set' end
            end

            def local_phone
              self.person_local_phone
            end

            def local_phone=(v)
              self.person_local_phone = v
            end

            def local_address
              self.person_local_addr
            end

            def local_city
              self.person_local_city
            end

            def local_postal_code
              self.person_local_pc
            end

            def local_province
              if loc_state then loc_state.province_shortDesc else 'no local province set' end
            end

            def local_country
              if loc_country then loc_country.country_shortDesc else 'no local country set' end
            end

            ######### end address helpers

            def local_state=(val)
              self[:person_local_province_id] = ::State.find_by_province_shortDesc(val).try(:id)
            end
            def permanent_state=(val)
              self[:province_id] = ::State.find_by_province_shortDesc(val).try(:id)
            end
            def emergency_state=(val)
              # we have no address for emergency contacts
            end

            def sanify_addresses
            end

            def permanent_same_as_local
              match = %w(city addr pc phone)
              match << %w(province_id person_local_province_id)
              for c in match
                if c.class == Array then
                  p, l = c      else
                  p = "person_#{c}"
                  l = "person_local_#{c}"
                  end

                lv = send(l)
                return false if lv.nil?
                pv = send(p)

                if lv != pv then return false end
              end

              true
            end

          end

          base.extend PersonClassMethods
        end

        CIM_MALE_GENDER_ID = 1
        CIM_FEMALE_GENDER_ID = 2
        US_MALE_GENDER_ID = 1
        US_FEMALE_GENDER_ID = 0


        MAX_SEARCH_RESULTS = 100

        def person_year
          person_year = cim_hrdb_person_years.first
          unless person_year
            person_year = cim_hrdb_person_years.create(:year_id => ::SchoolYear.default_year_id, :grad_date => Time.now)
          end
          return person_year
        end

        def is_hrdb_staff?
          !cim_hrdb_staff.nil?
        end

        def year_in_school
          person_year.school_year
        end

        def year_in_school_id
          cim_hrdb_person_years.first.try(:year_id)
        end

        # these will need to be implemented in the utopian CDM using Address
        def person_local_province() loc_state end
        def person_province() perm_state end
        def person_province_id() province_id end
        def person_province_id=(val) self[:province_id] = val end
        def person_local_country() loc_country end
        def person_country() perm_country end
        def person_country_id() country_id end
        def person_country_id=(val) self[:country_id] = val end

        def get_emerg()
          # really bizarre, but @emerg can get into a state where it's nil but not the NilClass
          # I tried printing some debug statements when this happens:
          #   @emerg.inspect='nil' @emerg.nil?='false' @emerg.is_a?(::Emerg)='' @emerg.class=''
          # Seems the only way to get out of this is look for the inspect of 'nil'
          # -AR
          if @emerg.inspect == "nil" then @emerg = nil end
          return @emerg if @emerg
          @emerg = emerg
          return @emerg if @emerg
          unless self.new_record?
            # required fields are a bit of a pain
            @emerg = ::Emerg.create!(:emerg_birthdate => Time.now, :emerg_contact2Mobile => '', :emerg_contact2Rship => '', :emerg_contact2Home => '', :emerg_passportExpiry => Time.now, :emerg_contact2Work => '', :emerg_contact2Email => '', :emerg_contact2Name => '', :person_id => id)
            @emerg.emerg_passportExpiry = nil
            @emerg.emerg_birthdate = nil
            @emerg.save!
          end
          return @emerg
        end


        # Attended and Unknown Status are not mapped
        ASSIGNMENTS_TO_ROLE = ActiveSupport::OrderedHash.new
        ASSIGNMENTS_TO_ROLE['Alumni'] = 'Alumni' # not sure why we have two Campus Alumni like roles..
        ASSIGNMENTS_TO_ROLE['Campus Alumni'] = 'Alumni'
        ASSIGNMENTS_TO_ROLE['Staff Alumni'] = 'Staff Alumni'
        ASSIGNMENTS_TO_ROLE['Current Student'] = 'Student'
        ASSIGNMENTS_TO_ROLE['Staff'] = 'Staff'

        def sync_cim_hrdb
          map_cim_hrdb_to_mt
        end

        def map_mt_to_cim_hrdb
          # TODO
        end

        # ministry and role contain what the new ministry_involvement should be set up
        # for those attributes
        def upgrade_ministry_involvement(ministry, role)
          atts = {
            :ministry_role_id => role.id,
            :ministry_id => ministry.id,
            :person_id => self.id,
            :admin => self.cim_hrdb_admins.count > 0,
            :end_date => nil
          }

          # find highest ministry involvement
          mi = self.ministry_involvements.find(:first, :conditions => ["#{::MinistryInvolvement.table_name + '.' + _(:ministry_id, :ministry_involvement)} IN (?)", ministry.id], :joins => :ministry_role, :order => _(:position, :ministry_role))

          if mi.nil?
            mi = ministry_involvements.create!(atts)
          else
            # don't demote them (higher roles have lower position values)
            if (mi.ministry_role.class == ::StaffRole && role.class == ::StudentRole) ||
                 (mi.ministry_role && mi.ministry_role.position < role.position)
              atts.delete :ministry_role_id
            end

            mi.update_attributes atts
          end
        end

        def get_highest_assignment
          return nil if assignments.empty?

          best_p = nil

          for a in assignments
            a_p = ASSIGNMENTS_TO_ROLE.keys.index(a.assignmentstatus.assignmentstatus_desc)
            if (a_p && !best_p) || (a_p && a_p > best_p)
              best_p = a_p
              best_a = a
            end
          end

          best_a
        end

        def map_cim_hrdb_to_mt(options = {})
          c4c = ::Ministry.find_by_name 'Campus for Christ'

          # assume if they already have involvements they're properly set up on the pulse
          return if ministry_involvements.present? || campus_involvements.present?

          # staff *must* have a cim_hrdb_staff entry
          if cim_hrdb_staff && cim_hrdb_staff.is_active == 1
            # look for a Staff assignment to determine campus
            staff_assign = ::Assignmentstatus.find_by_assignmentstatus_desc("Staff")
            campus = assignments.find_by_assignmentstatus_id(staff_assign).try(:campus)

            if campus
              mc = ::MinistryCampus.find(:last, :conditions => { :campus_id => campus.id })
              ministry = mc.try(:ministry)

              if ministry
                # finally, they have everything needed to be marked staff on the pulse
                staff_role = ::StaffRole.find_by_name('Staff')
                c4c_mi = ministry_involvements.find_or_create_by_ministry_id(c4c.id)
                c4c_mi.ministry_role_id = staff_role.id
                c4c_mi.start_date = Date.today
                c4c_mi.end_date = nil
                c4c_mi.save!

                # add staff team role
                unless ministry == c4c
                  staff_team_role = ::StaffRole.find_by_name('Staff Team')
                  team_mi = ministry_involvements.find_or_create_by_ministry_id(ministry.id)
                  team_mi.ministry_role_id = staff_team_role.id
                  team_mi.start_date = Date.today
                  team_mi.end_date = nil
                  team_mi.save!
                end
              end
            end
          end
        end

        # import information from the ciministry hrdb to the movement tracker database
        #
        # when secure flag is on, it will import staff with a cim_hrdb_assignment (as staff)
        # only if they cim_hrdb_staff entry
        #
        def map_cim_hrdb_to_mt_old(options = {})
          options = { :secure => true
          }.merge(options)

          c4c = ::Ministry.find_by_name 'Campus for Christ'

          if !self[:person_email].present?
            self[:person_email] = self.user.viewer_userID if self.user
            self.save
          end

          # ciministry hrdb uses assignments to track
          # both ministry involvement and campus involvements.
          # Movement Tracker uses two individual tables.
          a = get_highest_assignment
          return unless a

          campus = a.campus
          assignment = a.assignmentstatus.assignmentstatus_desc

          if campus && ASSIGNMENTS_TO_ROLE[assignment]

            # ministry involvement
            role = ::MinistryRole.find_by_name ASSIGNMENTS_TO_ROLE[assignment]

            # if they have a staff role (verify staff if secure flag is on)
            if (assignment == 'Staff' && options[:secure] ? !cim_hrdb_staff.nil? : true)
              staff = true

              # staff should get a staff team role on the ministry and a staff role in c4c
              mc = ::MinistryCampus.find_all_by_campus_id(campus).last
              if mc && mc.ministry
                upgrade_ministry_involvement(mc.ministry, ::MinistryRole.find_by_name('Staff Team'))
              end
              # they should also get a generic staff involvement
              upgrade_ministry_involvement(c4c, ::MinistryRole.find_by_name('Staff'))
            else
              staff = false
            end

            # add the appropriate campus involvements
            # not sure why, but it seems that the association breaks the person array
            # in the rake canada:import task.  It was making the person_id be 1, really
            # weird
            #ci = campus_involvements.find_or_create_by_campus_id campus.id
            ci = ::CampusInvolvement.find :first, :conditions => {
              :person_id => self.id,
              :campus_id => campus.id
            }
            ci ||= ::CampusInvolvement.new :person_id => self.id, :campus_id => campus.id

            school_year = cim_hrdb_person_years.first.try(:school_year)
            ci.ministry_id = c4c.id
            ci.campus_id = campus.id
            ci.graduation_date = graduation_date
            if staff
              ci.school_year = ::SchoolYear.find_by_year_desc "Alumni"
            else
              ci.school_year = school_year
            end
            ci.end_date = nil
            #begin
            ci.save!
            #rescue
            #  puts "self: #{self.inspect} ci: #{ci.inspect}"
            #end
          end
          true

          # add a staff ministry role if they're cim_hrdb_staff
          if !cim_hrdb_staff.nil?
            upgrade_ministry_involvement(c4c, ::MinistryRole.find_by_name('Staff'))
          end
        end

        def create_user_and_access_only(guid, uid)
          v = ::Person.create_viewer(guid, uid)
          self.user = v
          self.user.person = self
          self.setup_and_create_access(v)
        end

        def setup_and_create_access(v)
          #ag_st = AccountadminAccessgroup.find_by_accessgroup_key '[accessgroup_student]' #this returns nil currently. This is where we get an error
          ag_all = ::AccountadminAccessgroup.find_by_accessgroup_key '[accessgroup_key1]'
          #if ag_st
          #  ::AccountadminVieweraccessgroup.create! :viewer_id => v.id, :accessgroup_id => ag_st.id
          #end
          if ag_all
            ::AccountadminVieweraccessgroup.create! :viewer_id => v.id, :accessgroup_id => ag_all.id
          end
          ::Access.create :viewer_id => v.id, :person_id => self.id
        end

        def full_destroy
          # must destroy person and access before user can be destroyed because of validates_no_association_data
          uid = self.user.id
          self.access.try(:destroy)
          ::User.find(uid).try(:destroy)
          self.emerg.try(:destroy)
          self.cim_hrdb_person_years.each {|c| c.try(:destroy)}
          self.destroy
        end

        # TODO: I think this is redundant -- we should use !is_staff_somewhere? and 
        # it should be in utopian, not ca
        def is_student
          ministry_involvements.detect{ |mi| mi.ministry_role.is_a?(StaffRole) && mi.end_date.nil? }.nil?
        end



        
        module PersonClassMethods

          def create_viewer(guid, uid)
            v = ::User.new
            v.guid = guid
            v.language_id = 1
            v.viewer_isActive = true
            v.accountgroup_id = 15
            v.viewer_lastLogin = 0
            v.viewer_userID = uid
            v.save!
            #v.viewer_lastLogin = nil # hack to get by the create restriction

            v
          end

          def create_new_cim_hrdb_account(guid, fn, ln, uid)
            # first and last names can't be nil
            # rails insists on putting null into columns with emptry strings
            hack_fn = fn.nil?
            fn = 'fn' if hack_fn
            hack_ln = ln.nil?
            ln = 'ln' if hack_ln
            guid ||= ''
            p = ::Person.create! :person_fname => fn, :person_lname => ln,
              :person_legal_fname => 'lfn', :person_legal_lname => 'lln',
              :birth_date => nil, :person_email => uid
            p.person_fname = '' if hack_fn
            p.person_lname = '' if hack_ln
            p.person_legal_fname = ''
            p.person_legal_lname = ''
            p.save(false)

            p.create_user_and_access_only(guid, uid)

            p.user
          end

          def find_user(person, address)
            # is there a user with the same email?
            user = ::User.find(:first, :conditions => ["#{_(:username, :user)} = ?", address.email])
            if user && user.person.nil?
              # If we have an orphaned user record, might as well use it...
              person.email = address.email
              person.save(false)
              person.setup_and_create_access(user)
              p = person
            else
              p = user.person if user
            end
            unless p
              p = ::Person.find(:first, :conditions => {:person_email => address.email})
              p.create_user_and_access_only("", p.person_email) if p
            end
            return p
          end
        end
      end
    end
  end
end
