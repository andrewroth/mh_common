module Common
  module Core
    module Ca
      module Address
        def self.included(base)
          base.class_eval do
            def state=(state_abbrev)
              state = ::State.find :first, :conditions => { ::State._(:abbrev) => state_abbrev }
              if state
                self.province_id = state.id
              end
            end
          end
        end
      end
    end
  end
end
