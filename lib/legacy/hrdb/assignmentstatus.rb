module Legacy
  module Hrdb
    module Assignmentstatus

      def self.included(base)
        base.class_eval do
          has_many :assignments, :foreign_key => _(:status_id, :assignment)

          validates_no_association_data :assignments
        end

        base.extend AssignmentstatusClassMethods
      end

      # these constants must equal their respective records in the assignmentstatus table
      CAMPUS_ALUMNI = "Campus Alumni"
      UNKNOWN = "Unknown Status"
      STAFF_ALUMNI = "Staff Alumni"
      ATTENDED = "Attended"
      STAFF = "Staff"
      ALUMNI = "Alumni"
      CURRENT_STUDENT = "Current Student"

      module AssignmentstatusClassMethods
        # This method will return the status id associated with a given description
        def find_status_id(description)
          find(:first, :conditions => {_(:description) => description}).id
        end
      end

    end
  end
end
