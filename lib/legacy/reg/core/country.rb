module Legacy
  module Reg
    module Core
      module Country

        def self.included(base)
          base.class_eval do
            has_many :events,    :foreign_key => _(:event_id, :event)
          end
        end

        # constant must equal respective record in the countries table
        CANADA = "Canada"

      end
    end
  end
end
