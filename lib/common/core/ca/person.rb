module Common
  module Core
    module Ca
      module Person

        def self.included(base)
          base.class_eval do
            #  doesnt_implement_attributes :major => '', :minor => '', :url => '', :staff_notes => '', :updated_at => '', :updated_by => ''

            has_many :summer_reports, :class_name => "SummerReport"
            has_many :summer_report_reviewers, :class_name => "SummerReportReviewer"
            has_many :summer_reports_to_review, :through => :summer_report_reviewers, :source => :summer_report

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

            has_many :cim_reg_registrations
            has_many :cim_reg_events, :through => :cim_reg_registrations, :order => "event_startDate DESC"

            def update_addresses() end # noop since address info is in person
            def created_at=(v) end # noop since it would have set the id to the timestamp
            def user
              @user ||= users.first
            end
            def user=(v) @user = v end # fake setting the user, so that just_created memory-only flag will stick
            def person_extra()
              @person_extra ||= person_extra_ref || ::PersonExtra.new(:person_id => id)
            end
            def clear_extra_ref
              @person_extra = nil
            end
            def major() person_extra.major end
            def major=(val) person_extra.major = val end
            def minor() person_extra.minor end
            def minor=(val) person_extra.minor = val end
            def curr_dorm() person_extra.curr_dorm end
            def curr_dorm=(val) person_extra.curr_dorm = val end
            def local_dorm() person_extra.curr_dorm end
            def local_dorm=(val) person_extra.curr_dorm = val end
            def perm_dorm() person_extra.perm_dorm end
            def perm_dorm=(val) person_extra.perm_dorm = val end
            def permanent_dorm() person_extra.perm_dorm end
            def permanent_dorm=(val) person_extra.perm_dorm = val end
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
            def most_recent_involvement() campus_involvements.last end
            def primary_campus_involvement() most_recent_involvement end
            def primary_campus() most_recent_involvement.try(:campus) end
            def campus_shortDesc() primary_campus.try(:campus_shortDesc) end
            def campus_longDesc() primary_campus.try(:campus_shortDesc) end

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

            def permanent_address_line1() self.person_addr end
            def permanent_address_line2() "" end

            def local_address_line1() self.person_local_addr end
            def local_address_line2() "" end

            def permanent_city
              self.person_city
            end

            def permanent_city=(val)
              self.person_city = val
            end

            def local_province_short() local_province end
            def local_province_long() if loc_state then loc_state.province_desc else 'no perm province set' end; end
            def permanent_province_short() permanent_province end
            def permanent_province_long() if perm_state then perm_state.province_desc else 'no perm province set' end; end

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

            def local_country=(val)
              self.loc_country = ::Country.find_by_country_shortDesc(val)
            end

            def permanent_country=(val)
              self.perm_country = ::Country.find_by_country_shortDesc(val)
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

            def local_valid_until
              self[:local_valid_until]
            end

            def local_valid_until=(val)
              self[:local_valid_until] = val
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
          c4c = ::Ministry.find_by_name 'Power to Change - Students'

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
              ci.school_year = ::SchoolYear.find_by_year_desc "Graduated"
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
          #ag_all = ::AccountadminAccessgroup.find_by_accessgroup_key '[accessgroup_key1]'
          #if ag_st
          #  ::AccountadminVieweraccessgroup.create! :viewer_id => v.id, :accessgroup_id => ag_st.id
          #end
          #if ag_all
          #  ::AccountadminVieweraccessgroup.create! :viewer_id => v.id, :accessgroup_id => ag_all.id
          #end
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
        
        
        def update_from_latest_event_attendee
          latest_event_attendee = self.event_attendees.first(:order => "#{::EventAttendee._(:ticket_updated_at)} desc")
          
          # only update the person if the attendee info is newer than the last time their profile was updated
          if latest_event_attendee && latest_event_attendee.ticket_updated_at > Time.parse(self.updated_at.to_s).in_time_zone(latest_event_attendee.ticket_updated_at.zone)
            
            campus = ::Campus.find_campus_from_eventbrite(latest_event_attendee.campus)
            school_year = ::SchoolYear.first(:conditions => ["#{::SchoolYear._(:name)} = ?", latest_event_attendee.year_in_school])
            
            if campus && school_year
              self.add_or_update_campus(campus.id, school_year.id, campus.derive_ministry.id, "MT")
            end
            
            # update phone numbers
            self.cell_phone = latest_event_attendee.cell_phone if latest_event_attendee.cell_phone.present?
            current_address = self.current_address
            current_address.phone = latest_event_attendee.home_phone || latest_event_attendee.work_phone if latest_event_attendee.home_phone.present? || latest_event_attendee.work_phone.present?
            
            current_address.save!
            self.save!
          end
        end

        def merge(other)
          throw("Error: Can't merge self with self.") if other == self
          throw("Error: Person #{self.id} (self) does not have a User") unless self.user.present?
          throw("Error: Person #{other.id} (other) does not have a User") unless other.user.present?

          pat_db = Rails.configuration.database_configuration["pat_#{Rails.env}"]["database"]

          # PAT rows that can have viewer_id updated
          self.connection.execute("UPDATE #{pat_db}.eventgroup_coordinators SET viewer_id = #{self.user.id} WHERE viewer_id = #{other.user.id}")
          self.connection.execute("UPDATE #{pat_db}.notification_acknowledgments SET viewer_id = #{self.user.id} WHERE viewer_id = #{other.user.id}")
          self.connection.execute("UPDATE #{pat_db}.processors SET viewer_id = #{self.user.id} WHERE viewer_id = #{other.user.id}")
          self.connection.execute("UPDATE #{pat_db}.applns SET viewer_id = #{self.user.id} WHERE viewer_id = #{other.user.id}")
          self.connection.execute("UPDATE #{pat_db}.project_administrators SET viewer_id = #{self.user.id} WHERE viewer_id = #{other.user.id}")
          self.connection.execute("UPDATE #{pat_db}.project_directors SET viewer_id = #{self.user.id} WHERE viewer_id = #{other.user.id}")
          self.connection.execute("UPDATE #{pat_db}.project_staffs SET viewer_id = #{self.user.id} WHERE viewer_id = #{other.user.id}")
          self.connection.execute("UPDATE #{pat_db}.projects_coordinators SET viewer_id = #{self.user.id} WHERE viewer_id = #{other.user.id}")
          self.connection.execute("UPDATE #{pat_db}.support_coaches SET viewer_id = #{self.user.id} WHERE viewer_id = #{other.user.id}")
          self.connection.execute("UPDATE #{pat_db}.profiles SET viewer_id = #{self.user.id} WHERE viewer_id = #{other.user.id}")
          self.connection.execute("UPDATE #{pat_db}.eventgroup_coordinators SET viewer_id = #{self.user.id} WHERE viewer_id = #{other.user.id}")
          self.connection.execute("UPDATE #{pat_db}.notification_acknowledgments SET viewer_id = #{self.user.id} WHERE viewer_id = #{other.user.id}")

          # PAT rows that can be deleted
          self.connection.execute("DELETE FROM #{pat_db}.preferences WHERE viewer_id = #{other.user.id}")

          # Mpdtool MpdUser should be moved over only if there is not already one for self
          begin
            mpdtool_db = Rails.configuration.database_configuration["mpdtool_#{Rails.env}"]["database"]
            mpd_user = User.connection.execute("SELECT * FROM #{mpdtool_db}.mpd_users WHERE user_id = #{self.user.id}").first
            if mpd_user
              # keep the current one and delete the other's mpd_user
              self.connection.execute("DELETE FROM #{mpdtool_db}.mpd_users WHERE user_id = #{other.user.id}")
            else
              # use the other's mpd_user since self doesn't have one (though he might not have one either)
              self.connection.execute("UPDATE #{mpdtool_db}.mpd_users SET user_id = #{self.user.id} WHERE user_id = #{other.user.id}")
            end
          rescue
          end

          # Pulse rows that can be deleted
          other.timetable.try(:destroy)
          other.profile_picture.try(:destroy)
          other.person_extra.try(:destroy)
          other.updated_timetables.collect(&:destroy)
          other.free_times.collect(&:destroy)
          other.contract_signatures.collect(&:destroy)
          self.connection.execute("UPDATE #{::InvolvementHistory.table_name} SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{::MinistryInvolvement.table_name} SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{::CampusInvolvement.table_name} SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{::GroupInvolvement.table_name} SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{::ContactsPerson.table_name} SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{::GroupInvitation.table_name} SET recipient_person_id = #{self.id} WHERE recipient_person_id = #{other.id}")
          self.connection.execute("UPDATE #{::GroupInvitation.table_name} SET sender_person_id = #{self.id} WHERE sender_person_id = #{other.id}")
          self.connection.execute("UPDATE #{::Search.table_name} SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{::DismissedNotice.table_name} SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{::UserCode.table_name} SET user_id = #{self.user.id} WHERE user_id = #{other.user.id}")
          self.connection.execute("UPDATE #{::LabelPerson.table_name} SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{::Note.table_name} SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{::PersonEventAttendee.table_name} SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{::PersonTrainingCourse.table_name} SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{::Recruitment.table_name} SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{::Recruitment.table_name} SET recruiter_id = #{self.id} WHERE recruiter_id = #{other.id}")

          # Delete Other's intranet tables (including deleting other itself)
          intranet_db = Rails.configuration.database_configuration["intranet_#{Rails.env}"]["database"]
          other.emerg.try(:destroy) # cim_hrdb_emerg
          other.user.try(:destroy) # accountadmin_viewer
          other.access.try(:destroy) # cim_hrdb_access
          other.assignments.collect(&:destroy) # cim_hrdb_assignment
          self.connection.execute("DELETE FROM #{intranet_db}.cim_hrdb_admin WHERE person_id = #{other.id}")
          self.connection.execute("DELETE FROM #{intranet_db}.accountadmin_accountadminaccess WHERE viewer_id = #{other.user.id}")
          self.connection.execute("DELETE FROM #{intranet_db}.accountadmin_viewer WHERE viewer_id = #{other.user.id}")
          self.connection.execute("DELETE FROM #{intranet_db}.accountadmin_vieweraccessgroup WHERE viewer_id = #{other.user.id}")
          self.connection.execute("DELETE FROM #{intranet_db}.cim_hrdb_person_year WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{intranet_db}.cim_hrdb_staff SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{intranet_db}.cim_reg_registration SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{intranet_db}.cim_reg_eventadmin SET viewer_id = #{self.id} WHERE viewer_id = #{other.user.id}")
          self.connection.execute("UPDATE #{intranet_db}.summer_reports SET person_id = #{self.id} WHERE person_id = #{other.id}")
          self.connection.execute("UPDATE #{intranet_db}.summer_report_reviewers SET person_id = #{self.id} WHERE person_id = #{other.id}")

          # Destroy the other person!
          other.destroy
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

          def create_new_cim_hrdb_person(fn, ln, email)
            # first and last names can't be nil
            # rails insists on putting null into columns with emptry strings
            hack_fn = fn.nil?
            fn = 'fn' if hack_fn
            hack_ln = ln.nil?
            ln = 'ln' if hack_ln
            guid ||= ''
            p = ::Person.create! :person_fname => fn, :person_lname => ln,
              :person_legal_fname => 'lfn', :person_legal_lname => 'lln',
              :birth_date => nil, :person_email => email
            p.person_fname = '' if hack_fn
            p.person_lname = '' if hack_ln
            p.person_legal_fname = ''
            p.person_legal_lname = ''
            p.save(false)
            return p
          end

          def create_new_cim_hrdb_account(guid, fn, ln, uid)
            p = create_new_cim_hrdb_person(fn, ln, uid)
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
          
          def find_and_associate_person_to_event_attendee(event_attendee)
            # try to find a person to match the event_attendee, if found associate that person to the event_attendee by creating a PersonEventAttendee
            
            person = nil
            
            # first try to find by email address
            user = ::User.find(:first, :conditions => ["#{::User._(:username)} = ?", event_attendee.email])
            
            if user && user.person
              # found 'em, that was easy
              person = user.person
              Rails.logger.info("Matched event_attendee #{event_attendee.id} to person #{person.id} by email")
            else
              # no email matched, let's try something more complex...

              people_name_matches = ::Person.all(:conditions => ["#{::Person._(:first_name)} = ? and #{::Person._(:last_name)} = ?",
                                                 event_attendee.first_name, event_attendee.last_name])
              
              people_name_and_campus_matches = people_name_matches.select { |person| person.primary_campus.try(:matches_eventbrite_campus, event_attendee.campus) }
              
              case people_name_and_campus_matches.size
              when 1
                # found 'em
                person = people_name_and_campus_matches.first
                Rails.logger.info("Matched event_attendee #{event_attendee.id} to person #{person.id} by name and campus")
              when 0
                # give up, there's no one with this name and campus
                person = nil
              else
                # still more than one, keep going...
                
                people_name_campus_and_year_matches = people_name_and_campus_matches.select { |person| person.year_in_school.name == event_attendee.year_in_school }
                
                case people_name_campus_and_year_matches
                when 1
                  # found 'em
                  person = people_name_campus_and_year_matches.first
                  Rails.logger.info("Matched event_attendee #{event_attendee.id} to person #{person.id} by name, campus and year in school")
                else
                  # give up, there's no one with this name, campus and year_in_school
                  person = nil
                  
                end
              end
            end
            
            
            # if we found a person associate them with the event_attendee
            if person.present? && person.event_attendees.all(:conditions => {:id => event_attendee.id}).empty?
              person_event_attendee = ::PersonEventAttendee.new({:person_id => person.id, :event_attendee_id => event_attendee.id})
              person_event_attendee.save!
            end
            
            person
          end

        end
      end
    end
  end
end
