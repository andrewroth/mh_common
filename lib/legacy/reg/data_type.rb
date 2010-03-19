module Legacy
  module Reg
    module DataType

      def self.included(base)
        base.class_eval do
          has_many :fields, :foreign_key => _(:data_type_id, :field)
        end
      end

    end
  end
end
