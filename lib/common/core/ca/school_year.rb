module Common
  module Core
    module Ca
      module SchoolYear

        def self.included(base)
          base.extend SchoolYearClassMethods
        end
        
        def level() year_id.to_s end
      end

      module SchoolYearClassMethods
        def default_year_id() 9 end
      end
    end
  end
end
