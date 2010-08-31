module Common
  module Core
    module Person
      ADDRESS_PREFIX_TO_ASSOC = { 
        "local" => "current_address", 
        "permanent" => "permanent_address",
        "emergency" => "emergency_address"
      }

      ADDRESS_SUFFIX_TO_COLUMN = { 
        "address1_line" => "address1",
        "address2_line" => "address2",
        "city" => "city",
        "postal_code" => "zip",
        "phone" => "phone",
        "alternate_phone" => "alternate_phone",
        "valid_until" => "end_date",
        "country" => "country",
        "state" => "state"
      } 

      def self.included(base)
        base.class_eval do
          include ActiveRecord::ConnectionAdapters::Quoting

          attr_accessor :just_created

          has_many :emails, :class_name => "Email", :foreign_key => "sender_id"

          # Campus Relationships
          has_many :involvement_history
          has_many :all_campus_involvements, :class_name => "CampusInvolvement", :foreign_key => _(:person_id), :order => 'end_date DESC' #, :include => [:ministry, :campus]
          has_many :campus_involvements, :class_name => "CampusInvolvement", :foreign_key => _(:person_id), :conditions => {_(:end_date, :campus_involvement) => nil}
          has_many :campuses, :through => :campus_involvements, :order => ::Campus.table_name+'.'+_(:name, :campus)
          has_many :all_campuses, :through => :all_campus_involvements, :class_name => 'Campus', :source => :campus
          belongs_to  :primary_campus_involvement, :class_name => "CampusInvolvement", :foreign_key => _(:primary_campus_involvement_id)
          # accepts_nested_attributes_for :primary_campus_involvement
          has_one  :primary_campus, :class_name => "Campus", :through => :primary_campus_involvement, :source => :campus
          has_many :ministry_involvements, :class_name => "MinistryInvolvement", :foreign_key => _(:person_id, :ministry_involvement), :conditions => {_(:end_date, :ministry_involvement) => nil}
          has_many :all_ministry_involvements, :class_name => "MinistryInvolvement", :foreign_key => _(:person_id, :ministry_involvement), :order => 'end_date DESC'
          has_many :ministries, :through => :ministry_involvements, :order => ::Ministry.table_name+'.'+_(:name, :ministry)
          has_many :campus_ministries, :through => :campus_involvements, :class_name => "Ministry", :source => :ministry
          has_one :responsible_person, :class_name => "Person", :through => :ministry_involvements
          has_many :involvements_responsible_for, :class_name => "MinistryInvolvement", :foreign_key => "responsible_person_id"
          has_many :people_responsible_for, :class_name => "Person", :through => :involvements_responsible_for, :source => :person
         
          # Address Relationships
          has_many :addresses, :class_name => "Address", :foreign_key => _(:person_id, :address)
          has_one :current_address, :class_name => "CurrentAddress", :foreign_key => _(:person_id, :address), :conditions => _(:address_type, :address) + " = 'current'"
          has_one :permanent_address, :class_name => "PermanentAddress", :foreign_key => _(:person_id, :address), :conditions => _(:address_type, :address) + " = 'permanent'"
          has_one :emergency_address, :class_name => "EmergencyAddress", :foreign_key => _(:person_id, :address), :conditions => _(:address_type, :address) + " = 'emergency1'"
          
          # Conferences
          has_many :conference_registrations, :class_name => "ConferenceRegistration", :foreign_key => _(:person_id, :conference_registration)
          has_many :conferences, :through => :conference_registrations
          
          # STINTs
          has_many :stint_applications, :class_name => "StintApplication", :foreign_key => _(:person_id, :stint_application)
          has_many :stint_locations, :through => :stint_applications
        
          # Users
          belongs_to :user, :class_name => "User", :foreign_key => _(:user_id)
          
          # Emergency Information
          has_one :emerg
          
          has_many :imports
          
          has_one :timetable, :class_name => "Timetable", :foreign_key => _(:person_id, :timetable)
          has_many :free_times, :through => :timetable, :order => "#{_(:day_of_week, :free_times)}, #{_(:start_time, :free_times)}"
          
          # Searches
          has_many :searches, :class_name => "Search", :foreign_key => _(:person_id, :search), :order => "#{_(:updated_at, :search)} desc"
        
          # Correspondences
          has_many :correspondences
          
          validates_presence_of _(:first_name)
          validates_presence_of _(:last_name), :on => :update
          # validates_presence_of _(:gender)
          
          validate :birth_date_is_in_the_past
        
          has_one :profile_picture, :class_name => "ProfilePicture", :foreign_key => _("person_id", :profile_picture)
          
          before_save :update_stamp
          before_create :create_stamp
          after_create do |person| person.just_created = true end

          def gender=(value)
            if value.present?
              self[:gender] = (male?(value) ? 1 : 0)
            end
          end

          def gender_us_id
            gender
          end

          def email
            self[:email] || self[:"#{::Person._(:email)}"] || primary_email
          end

          # Note that since the email is stored in address, the email can't be set on a new
          # record.  Actually, it can get set and get, it's just not saved to the db after
          # the record is created.  This is because after_create callback is done in the 
          # transaction, so the foreign key for address back to person can't be determined.
          # So we need to create the person objects first, then save the email after.
          # Cdn schema is different and does have email in person.
          # -AR June 24
          def email=(value)
            if new_record?
              @primary_email = value
            else
              ca = current_address
              ca ||= self.addresses.new(:address_type => 'current')
              ca.email = value
              ca.save
            end
          end
          
          after_save do |record|
            record.update_addresses
          end

          def update_addresses
            current_address.save! if current_address.present?
            permanent_address.save! if permanent_address.present?
            emergency_address.save! if emergency_address.present?
          end

          ADDRESS_PREFIX_TO_ASSOC.each_pair do |method_prefix, assoc|
            ADDRESS_SUFFIX_TO_COLUMN.each_pair do |method_suffix, column|
              define_method("#{method_prefix}_#{method_suffix}") do
                self.send(assoc).send(:try, column)
              end
              define_method("#{method_prefix}_#{method_suffix}=") do |val|
                address = send(assoc) || send("create_#{assoc}")
                address.send("#{column}=", val)
              end
            end
          end

          def permanent_same_as_local
            ADDRESS_SUFFIX_TO_COLUMN.keys.each do |column|
              if send("local_#{column}") != send("permanent_#{column}")
                return false
              end
            end
            return true
          end
      
          base.extend PersonClassMethods
        end
      end
      
      def campus(o = {}) primary_campus end

      #liquid_methods :first_name, :last_name
      def to_liquid
        { "hisher" => hisher, "himher" => himher, "heshe" => heshe, "first_name" => first_name, "last_name" => last_name, "preferred_name" => preferred_name, "user" => user, "currentaddress" => current_address }
      end
      
      def most_nested_ministry
        ministries.inject(nil) { |best, ministry|
          if best
            ministry.ancestors.length > best.ancestors.length ? ministry : best
          else
            ministry
          end
        }
      end


      # wrapper to make gender display nicely with crusade tables
      def human_gender(value = nil)
        gender = value || self.gender
        ::Person.human_gender(gender)
      end
      
      def gender=(value)
        if value.present?
          self[:gender] = (male?(value) ? 1 : 0)
        end
      end
      
      def male?(value = nil)
        human_gender(value) == 'Male'
      end

      def sanify_addresses
        current_address.sanify if current_address
        permanent_address.sanify if permanent_address
      end

      def hisher
        hisher = human_gender == 'Male' ? 'his' : 'her'
      end

      def himher
        himher = human_gender == 'Male' ? 'him' : 'her'
      end

      def heshe
        heshe = human_gender == 'Male' ? 'he' : 'she'
      end
      
      def full_name
        (preferred_first_name || first_name).to_s + ' ' + (preferred_last_name || last_name).to_s
      end

      def primary_email
        return @primary_email if @primary_email.present?
        @primary_email = current_address.try(:email)
        @primary_email = user.username if @primary_email.blank? && user && user.username =~ /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i
        @primary_email
      end
      
      def email
        self[:email] || primary_email
      end
      
      def email=(value)
        ca = current_address
        ca ||= self.addresses.new(:address_type => 'current')
        ca.email = value
        ca.save
      end
      
      def ministry_tree
        res =  lambda {
          ministries = self.ministries.find(:all, :include => [:parent, :children])
          (ministries.collect(&:ancestors).flatten + ministries.collect(&:descendants).flatten).uniq
        }
        Rails.env.production? ? Rails.cache.fetch([self, 'ministry_tree']) {res.call} : res.call
      end
      
      def campus_list(ministry_involvement)
        res =  lambda {
          if ministry_involvement && ministry_involvement.ministry_role.class == ::StudentRole
            self.campuses
          else
            self.ministries.collect {|ministry| ministry.unique_campuses }.flatten.uniq
          end
        }
        Rails.env.production? ? Rails.cache.fetch([self, 'campus_list', ministry_involvement]) {res.call} : res.call
      end
      
      def role(ministry)
        @roles ||= {}
        unless @roles[ministry]
          mi = ministry_involvements.find(:first, :conditions => "#{_(:person_id, :ministry_involvement)} = #{self.id} AND
                                                                #{_(:ministry_id, :ministry_involvement)} = #{ministry.id}")
          @roles[ministry] = mi ? mi.ministry_role : nil
        end
        @roles[ministry]
      end
      
      def admin?(ministry)
        mi = ::MinistryInvolvement.find(:first, :conditions => "#{_(:person_id, :ministry_involvement)} = #{self.id} AND
                                                              #{_(:ministry_id, :ministry_involvement)} IN (#{ministry.ancestor_ids.join(',')}) AND
                                                              #{_(:admin, :ministry_involvement)} = 1")
        return !mi.nil?
      end
      
      def initialize_addresses(types = nil)
        self.current_address ||= ::CurrentAddress.new
        self.permanent_address ||= ::PermanentAddress.new
        self.emergency_address ||= ::EmergencyAddress.new
      end
      
      # return true or false based on update / save success
      def add_or_update_campus(campus_id, school_year_id, ministry_id, added_by)
        # Make sure they're not already on this campus
        ci = ::CampusInvolvement.find_by_campus_id_and_person_id(campus_id, self.id)
        if ci
          # make sure school year is the same
          if ci.school_year_id != school_year_id
            ci.school_year_id = school_year_id
            ci.save
          end
        else
          ci = campus_involvements.create(
            :campus_id => campus_id, :ministry_id => ministry_id, 
            :added_by_id => added_by, :start_date => Time.now(), 
            :school_year_id => school_year_id)
        end
        ci
      end

      # return true or false based on update / save success
      def add_or_update_ministry(ministry_id, role_id)
        role = ::MinistryRole.find role_id

        # TODO: add security so that only staff can add other staff roles
        
        # Add the person to the ministry
        mi = ::MinistryInvolvement.find_by_ministry_id_and_person_id(ministry_id, self.id)
        if mi
          mi.ministry_role_id = role.id 
          mi.save
        else
          mi = ministry_involvements.create(:ministry_id => ministry_id, :ministry_role_id => role.id, :start_date => Time.now) 
        end
        mi
      end
      
      # will import all details existing on gcx profile into the user
      def import_gcx_profile(proxy_granting_ticket)
        service_uri = "https://www.mygcx.org/system/report/profile/attributes"
        proxy_ticket = CASClient::Frameworks::Rails::Filter.client.request_proxy_ticket(proxy_granting_ticket, service_uri).ticket
        ticket = CASClient::ServiceTicket.new(proxy_ticket, service_uri)
        return false unless proxy_ticket
        uri = "#{service_uri}?ticket=#{proxy_ticket}"
        logger.debug('URI: ' + uri)
        uri = URI.parse(uri) unless uri.kind_of? URI
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = (uri.scheme == 'https')
        raw_res = https.start do |conn|
          conn.get("#{uri}")
        end
        doc = Hpricot(raw_res.body)
        return false if (doc/'attribute').empty?
        ca = current_address
        (doc/'attribute').each do |attrib|
          if attrib['value'].present?
            ca.email = attrib['value'].downcase if attrib['displayname'] == 'emailAddress' && ca
            ca.city = attrib['value'] if attrib['displayname'] == 'city' && ca
            ca.phone = attrib['value'] if attrib['displayname'] == 'landPhone' && ca
            ca.alternate_phone = attrib['value'] if attrib['displayname'] == 'mobilePhone' && ca
            ca.zip = attrib['value'] if attrib['displayname'] == 'zip' && ca
            ca.address1 = attrib['value'] if attrib['displayname'] == 'location' && ca
            first_name = attrib['value'] if attrib['displayname'] == 'firstName'
            last_name = attrib['value'] if attrib['displayname'] == 'lastName'
            birth_date = attrib['value'] if attrib['displayname'] == 'birthdate'
            gender = attrib['value'] if attrib['displayname'] == 'gender'
          end
        end
        ca.save(false) if ca
        self.save(false)
      end
      
      # Question: what does this help with?
      def most_recent_involvement
        @most_recent_involvement = primary_campus_involvement || campus_involvements.last
      end
      
      # for students, use their campuse involvements; for staff, use ministry teams
      def working_campuses(ministry_involvement)
        return @working_campuses if @working_campuses
        return [] unless ministry_involvement
        if ministry_involvement.ministry_role.is_a?(::StudentRole)
          @working_campuses = campuses
        elsif ministry_involvement.ministry_role.is_a?(::StaffRole)
          @working_campuses = ministry_involvement.ministry.campuses
        end
      end

      # i18n format
      def birth_date=(value)
        if value.is_a?(String) && !value.blank?
          self[:birth_date] = Date.strptime(value, (I18n.t 'date.formats.default'))
        else
          self[:birth_date] = value
        end
      end
      
      def is_staff_somewhere?
        root_ministry = ::Ministry.first.try(:root)
        return false unless root_ministry
        ::MinistryInvolvement.find(:first, :conditions =>
           ["#{_(:person_id, :ministry_involvement)} = ? AND (#{_(:ministry_role_id, :ministry_involvement)} IN (?) OR admin = 1) AND #{_(:end_date, :ministry_involvement)} is null",
             id, root_ministry.staff_role_ids]).present?
      end

      def get_emerg
        return @emerg if @emerg 
        @emerg = emerg
        return @emerg if @emerg 
        unless self.new_record?
          @emerg = create_emerg
        end
      end

=begin
      def permanent_address1_line
        permanent_address.try(:address1)
      end

      def permanent_address2_line
        permanent_address.try(:address1)
      end

      def local_address1_line
        current_address.try(:address1)
      end

      def local_address2_line
        current_address.try(:address2)
      end

      def local_city
        current_address.try(:city)
      end

      def local_postal_code
        current_address.try(:zip)
      end

      def local_phone
        current_address.try(:phone)
      end

      def local_valid_until
        current_address.end_date
      end

      def permanent_same_as_local
        # TODO
        false
      end
=end

      def highest_ministry_involvement_with_particular_role(ministry_role)
        if ministry_role
          ministry_involvement = ::MinistryInvolvement.all(:first, :joins => :ministry,
                                                           :conditions => {:person_id => self.id, :ministry_role_id => ministry_role.id, :end_date => nil},
                                                           :order => "#{::Ministry.table_name}.parent_id ASC")
          ministry_involvement ? ministry_involvement.first : nil
        else
          nil
        end
      end

      def ministries_involved_in_with_children(with_ministry_roles = nil)
        ministries = []

        unless with_ministry_roles.nil?
          self.ministry_involvements.each do |mi|
            if with_ministry_roles.include?(mi.ministry_role) then
              ministries |= mi.ministry.myself_and_descendants
            end
          end
        else
          self.ministry_involvements.each do |mi|
            ministries |= mi.ministry.myself_and_descendants
          end
        end

        ministries
      end

      def campuses_under_my_ministries_with_children(with_ministry_roles = nil)
        ministries = ministries_involved_in_with_children(with_ministry_roles)
        campuses = []

        ministries.each do |ministry|
          campuses |= ministry.unique_campuses
        end

        campuses
      end

      def has_permission_from_ministry_or_higher(action, controller, ministry)
        ministry_ids = ministry.ancestors.collect{|m| m.id}

        involvements = ::MinistryInvolvement.all(:conditions => ["#{_(:ministry_id, :ministry_involvement)} IN (?) AND #{_(:person_id, :ministry_involvement)} = ?", ministry_ids, self.id])

        involvements.each do |involvement|
          mrps = ::MinistryRolePermission.all(:joins => :permission,
            :conditions => ["#{_(:ministry_role_id, :ministry_role_permission)} = ? AND #{_(:action, :permission)} = ? AND #{_(:controller, :permission)} = ?", involvement.ministry_role_id, action, controller])
          return true if mrps.any?
        end

        false
      end

      def preferred_name() preferred_first_name end
      def preferred_name=(val) self[:preferred_first_name] = val end
      # use last_name for preferred_last_name if none set
      def preferred_last_name() self[:preferred_last_name] || last_name end

      # Just realized this would be better implemented by looping all
      # ministry involvements with student roles.  Don't have time to do
      # it now.  -AR June 18, 2010.
      def archive_all_student_ministry_involvements
        campus_involvements.each do |ci|
          if mi = ci.find_ministry_involvement
            ci.new_student_history.save!
            mi.end_date = Date.today
            mi.save!
          end
        end
      end

      protected

      def update_stamp
        self.updated_at = Time.now
        self.updated_by = 'MT'
      end

      def create_stamp
        update_stamp
        self.created_at = Time.now
        self.created_by = 'MT'
      end

      private

      def birth_date_is_in_the_past
        if !birth_date.nil?
          if (birth_date <=> Date.today) > 0
            errors.add(:birth_date, 'should be in the past')
          end
        end
      end

    end

    module PersonClassMethods
      def human_gender(gender)
        if [0,1,'0','1'].include?(gender)
          gender = ((gender.to_s == '0') ? 'Female' : 'Male')
        end
        if ['M','F'].include?(gender)
          gender = gender == 'F' ? 'Female' : 'Male'
        end
        gender ? gender.titlecase : nil
      end
      
      # Question: what is this finding? a user who has the username and email address provided?
      def find_exact(person, address)
        # check based on username first
        user = ::User.find(:first, :conditions => ["#{_(:username, :user)} = ?", address.email])
        if user && user.person.nil?
          # If we have an orphaned user record, might as well use it...
          user.person = person
          person.save(false)
          p = person
        else
          p = user.person if user
        end
        unless p
          address = ::CurrentAddress.find(:first, :conditions => ["#{_(:email, :address)} = ?", address.email])
          p = address.person if address
          p.user ||= ::User.create!(_(:username, :user) => address.email) if p
        end
        return p
      end

      def search(search, page, per_page)
        if search then
          ::Person.paginate(:page => page,
                            :per_page => per_page,
                            :conditions => ["concat(#{_(:first_name, :person)}, \" \", #{_(:last_name, :person)}) like ? " +
                                                "or #{_(:id, :person)} like ? ",
                                                "%#{search}%", "%#{search}%"])
        else
          nil
        end
      end

      # this method was originally imported from the PAT April 13, 2010 -AR
      # TODO: this search helper can be mergd with #search above if options are added to not return paginated results
      def search_by_name(name)
        return nil if name.nil?
        name.strip!
        fname = name.sub(/ +.+/i, '')
        lname = name.sub(/.+ +/i, '') if name.include? " "
        if !lname.nil?
          people = ::Person.find(:all,
                               :conditions => ["#{_(:first_name, :person)} like ? AND #{_(:last_name, :person)} like ?", "%#{fname}%", "%#{lname}%"],
                               :order => "#{_(:first_name, :person)}, #{_(:last_name, :person)}")
        else
          people = ::Person.find(:all,
                               :conditions => ["#{_(:first_name, :person)} like ? OR #{_(:last_name, :person)} like ?", "%#{fname}%", "%#{fname}%"],
                               :order => "#{_(:first_name, :person)}, #{_(:last_name, :person)}")
        end

        people
      end

    end
  end
end
