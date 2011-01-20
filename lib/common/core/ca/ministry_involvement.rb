module Common
  module Core
    module Ca
      module MinistryInvolvement
        def self.included(base)
          base.class_eval do
            before_save :set_graduated_school_year_if_involved_alumni
          end
        end

        protected

        def set_graduated_school_year_if_involved_alumni
          if self.ministry_role.name == "Alumni"
            # automatically set the person's campus involvements to be graduated
            graduated = ::SchoolYear.first(:conditions => ["#{::SchoolYear._(:name)} = ?", "Graduated"])
            self.person.campus_involvements.each do |ci|
              ci.school_year = graduated
              ci.save
            end
          end
        end

      end
    end
  end
end
