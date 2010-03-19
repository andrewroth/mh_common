module Legacy
  module Reg
    module FieldValue

      def self.included(base)
        base.class_eval do
          belongs_to :field, :foreign_key => _(:field_id)
          belongs_to :registration, :foreign_key => _(:registration_id)
        end
      end

      # constants to define human readable field values
      CHECKBOX_TRUE = "yes"
      CHECKBOX_FALSE = "no"
      PASSWORD = "••••••••••"


      def human_value

        case self.field.field_type.description

        when FieldType::CHECKBOX
          case self.value.to_i
          when 0
            human = CHECKBOX_FALSE
          when 1
            human = CHECKBOX_TRUE
          end

        when FieldType::PASSWORD
          human = PASSWORD
        when FieldType::TEXTAREA
          human = self.value
        when FieldType::TEXTBOX
          human = self.value

        end

        human
      end

    end
  end
end
