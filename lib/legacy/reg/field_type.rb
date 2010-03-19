module Legacy
  module Reg
    module FieldType

      def self.included(base)
        base.class_eval do
          has_many :fields, :foreign_key => _(:type_id, :field)

        end
      end

      # these constants must equal their respective records in the field_types table
      CHECKBOX = "checkbox"
      TEXTBOX = "textbox"
      TEXTAREA = "textarea"
      PASSWORD = "password"

    end
  end
end
