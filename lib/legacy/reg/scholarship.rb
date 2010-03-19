module Legacy
  module Reg
    module Scholarship

      def self.included(base)
        base.class_eval do
          belongs_to :registration, :foreign_key => _(:registration_id)

          validates_presence_of _(:amount), _(:source_account), _(:source_description)
          validates_numericality_of _(:amount)
        end
      end

    end
  end
end
