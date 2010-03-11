module Common
  module Core
    module Ca
      module SchoolYear

        def self.included(base)
          base.class_eval do

          end
        end
        
        def level() year_id.to_s end

      end
    end
  end
end
