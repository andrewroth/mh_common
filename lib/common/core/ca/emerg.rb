module Common
  module Core
    module Ca
      module Emerg
        def self.included(base)
          base.class_eval do
            belongs_to :person
            belongs_to :health_state, :class_name => "State", :foreign_key => "health_province_id"

            def contact_home_phone
              emerg_contactHome
            end

            def contact_mobile_phone
              emerg_contactMobile
            end

            def contact_work_phone
              emerg_contactWork
            end

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

            def birth_date
              person.try(:birth_date)
            end

            def birthdate() birth_date end
          end
        end
      end
    end
  end
end
