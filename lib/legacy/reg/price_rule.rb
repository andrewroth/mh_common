module Legacy
  module Reg
    module PriceRule

      def self.included(base)
        base.class_eval do
          belongs_to :price_rule_type, :foreign_key => _(:type_id)
          belongs_to :field, :foreign_key => _(:field_id)
          belongs_to :event, :foreign_key => _(:event_id)
        end
      end


      def applies_to_registration?(registration)

        applies = false

        case self.price_rule_type.description
        when PriceRuleType::FORM_ATTRIBUTE
          applies = form_attribute_rule_applies_to_registration?(registration)

        when PriceRuleType::DATE
          applies = date_rule_applies_to_registration?(registration)

        when PriceRuleType::VOLUME
          applies = volume_rule_applies_to_registration?(registration)

        when PriceRuleType::CAMPUS
          applies = campus_rule_applies_to_registration?(registration)
        end

        applies
      end



      private


      def form_attribute_rule_applies_to_registration?(registration)
        user_value = FieldValue.all( :select => "#{__(:value, :field_value)}",
                                     :conditions => ["#{__(:registration_id, :field_value)} = ? AND #{__(:field_id, :field_value)} = ?", registration.id, self.field_id] )

        user_value.first.value == self.value ? true : false
      end


      def date_rule_applies_to_registration?(registration)
          rule_time = Time.parse(self.value)
          registration_time = Time.parse(registration.date.to_s)

          registration_time <= rule_time ? true : false
      end


      def volume_rule_applies_to_registration?(registration)
        assigned_campus = registration.person.get_best_assigned_campus()

        campus_registrations = registration.event.registrations_from_campus(assigned_campus)

        campus_registrations.size >= self.value.to_i ? true : false
      end


      def campus_rule_applies_to_registration?(registration)
        assigned_campus = registration.person.get_best_assigned_campus()
        assigned_campus.id == self.value ? true : false
      end


    end
  end
end
