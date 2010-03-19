module Legacy
  module Reg
    module SuperAdmin

      def self.included(base)
        base.class_eval do
          belongs_to :user, :foreign_key => _(:user_id)
        end
      end

    end
  end
end
