module Common
  module Core
    module Ca
      module Emerg
        def self.included(base)
          base.class_eval do
            belongs_to :person
            belongs_to :health_state, :class_name => "State", :foreign_key => "health_province_id"

            def health_coverage_country
              health_state.try(:country).try(:abbrev)
            end

            def health_coverage_country=(v)
              # country is derived through the state association
            end

            def health_coverage_state
              health_state.try(:abbrev)
            end

            def health_coverage_state=(v)
              s = ::State.find :first, :conditions => { ::State._(:abbrev) => v }
              self[:health_province_id] = s.try(:id)
            end
          end
        end
      end
    end
  end
end
