module Legacy
  module Hrdb
    module Assignmentstatus

      def self.included(base)
        base.class_eval do
          has_many :assignments

          validates_no_association_data :assignments
        end
      end

      module AssignmentstatusClassMethods
        # This method will return the status id associated with a given description
        def find_status_id(description)
          find(:first, :conditions => {_(:description) => description}).id
        end
      end

    end
  end
end
