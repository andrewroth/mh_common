module Legacy
  module Reg
    module CampusAccess

      def self.included(base)
        base.class_eval do
          belongs_to :event_admin, :foreign_key => _(:event_admin_id)
          belongs_to :campus, :foreign_key => _(:campus_id)
        end
      end

    end
  end
end
