module Common
  module Core
    module Ca
      module MinistryInvolvement
        def self.included(base)
          base.class_eval do
            load_mappings
            before_save :set_graduated_school_year_if_involved_alumni
          end

          base.extend MinistryInvolvementMethods
        end

        def promote_student_to_staff(new_staff_role_id)
          return unless self.ministry_role.class == ::StudentRole

          new_role = ::MinistryRole.first(:conditions => {:id => new_staff_role_id})
          return unless new_role.class == ::StaffRole

          self.update_ministry_role_and_history(new_staff_role_id)

          # update or create a Campus for Christ staff role to have the "Staff" role
          c4c_role = ::MinistryInvolvement.find_by_ministry_id_and_person_id(2, self.person.id)
          staff_role = ::StaffRole.first(:conditions => {:name => "Staff"})
          unless c4c_role.present?
            c4c_role = self.person.ministry_involvements.create(:ministry_id => 2, :start_date => Time.now)
            c4c_role.ministry_role_id = staff_role.id
            c4c_role.save!
          else
            c4c_role.update_ministry_role_and_history(staff_role.id)
          end
        end


        protected

        def set_graduated_school_year_if_involved_alumni
          mr = ::MinistryRole.find(self.ministry_role_id)
          if mr && mr.name == "Alumni"
            # automatically set the person's campus involvements to be graduated
            graduated = ::SchoolYear.first(:conditions => ["#{::SchoolYear._(:name)} = ?", "Graduated"])
            self.person.campus_involvements.each do |ci|
              ci.school_year = graduated
              ci.save
            end
          end
        end


        module MinistryInvolvementMethods

          def build_highest_ministry_involvement_possible(person = nil)
            mi = ::MinistryInvolvement.new
            mi.person_id = person.nil? ? nil : person.id
            mi.ministry_id = 1
            mi.start_date = Date.today
            mi.admin = 1
            mi.ministry_role_id = ::StaffRole.find(:first, :order => :position).id
            mi
          end

        end

      end
    end
  end
end
