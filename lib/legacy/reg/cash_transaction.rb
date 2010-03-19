module Legacy
  module Reg
    module CashTransaction

      def self.included(base)
        base.class_eval do
          belongs_to :registration, :foreign_key => _(:registration_id)

          validates_presence_of _(:registration_id), _(:staff_name), _(:received), _(:amount_paid)
          validates_numericality_of _(:amount_paid)
        end
      end

      # these constants aren't in the database
      # they define what is displayed as summary for all cash transactions of a registration
      CASH_RECEIVED = "yes"
      NO_CASH_RECEIVED = "no"
      SOME_CASH_RECEIVED = "partially"
      NO_CASH_TRANSACTIONS = ""


      def human_received
        case self.received
        when 0
          NO_CASH_RECEIVED
        when 1
          CASH_RECEIVED
        end
      end

    end
  end
end
