module Legacy
  module Reg
    module RegistrationStatus

      def self.included(base)
        base.class_eval do

          has_many :registrations, :foreign_key => _(:status_id, :registration)
        end

        base.extend RegistrationStatusClassMethods
      end

      # these constants must equal their respective records in the registration_statuses table
      UNASSIGNED = "Unassigned"
      REGISTERED = "Registered"
      CANCELLED  = "Cancelled"
      INCOMPLETE = "Incomplete"

      module RegistrationStatusClassMethods

        def get_all_statuses(order_field = :id, order = "DESC")
          order = order.upcase
          order = "DESC" if (order != "ASC" && order != "DESC")

          RegistrationStatus.all(:order => _(order_field) + " " + order + ", " + _(:id) + " " + order)
        end

      end

    end
  end
end
