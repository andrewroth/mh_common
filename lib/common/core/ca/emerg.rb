module Common
  module Core
    module Ca
      module Emerg
        def self.included(base)
          base.class_eval do
            belongs_to :person
            belongs_to :health_state, :class_name => "State", :foreign_key => "health_province_id"

            def passport_number
              self.emerg_passportNum
            end

            def passport_origin
              self.emerg_passportOrigin
            end

            def passport_expiry
              self.emerg_passportExpiry
            end

            def contact_name
              self.emerg_contactName
            end

            def contact_relationship
              self.emerg_contactRship
            end

            def contact_home_phone
              self.emerg_contactHome
            end

            def contact_work_phone
              self.emerg_contactWork
            end

            def contact_mobile_phone
              self.emerg_contactMobile
            end

            def contact_email
              self.emerg_contactEmail
            end

            def contact2_name
              self.emerg_contact2Name
            end

            def contact2_relationship
              self.emerg_contact2Rship
            end

            def contact2_home_phone
              self.emerg_contact2Home
            end

            def contact2_work_phone
              self.emerg_contact2Work
            end

            def contact2_mobile_phone
              self.emerg_contact2Mobile
            end

            def contact2_email
              self.emerg_contact2Email
            end

            def birthdate
              self.emerg_birthdate
            end

            def medical_notes
              self.emerg_medicalNotes
            end

            def health_province_shortDesc
              health_province.province_shortDesc if health_province
            end

            def health_province_longDesc
              health_province.province_desc if health_province
            end

            def extended_medical_plan_number
              self.medical_plan_number
            end

            def extended_medical_plan_carrier
              self.medical_plan_carrier
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

            def health_province() health_state end
          end
        end
      end
    end
  end
end
