module Legacy
  module Reg
    module EventAdmin

      def self.included(base)
        base.class_eval do
          has_many :campus_accesses
          belongs_to :user, :foreign_key => _(:user_id)
          belongs_to :event, :foreign_key => _(:event_id)
          belongs_to :privilege, :foreign_key => _(:privilege_id)
        end
      end

    end
  end
end
