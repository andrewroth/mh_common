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
            
          end
        end

      end
    end
  end
end
