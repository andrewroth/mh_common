module Legacy
  module Reg
    module PriceRuleType

      def self.included(base)
        base.class_eval do
          has_many :price_rules, :foreign_key => _(:type_id, :price_rule)
        end
      end

      # these constants must equal their respective records in the price_rule_types table
      FORM_ATTRIBUTE = "Form Attribute"
      DATE = "Date"
      VOLUME = "Volume"
      CAMPUS = "Campus"


    end
  end
end
