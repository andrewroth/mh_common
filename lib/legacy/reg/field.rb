module Legacy
  module Reg
    module Field

      def self.included(base)
        base.class_eval do
          belongs_to :event, :foreign_key => _(:event_id)
          belongs_to :data_type, :foreign_key => _(:data_type_id)
          belongs_to :field_type, :foreign_key => _(:type_id)
          has_many :price_rules, :foreign_key => _(:field_id, :price_rule)
          has_many :field_values, :foreign_key => _(:field_id, :field_value)
        end
      end

    end
  end
end
