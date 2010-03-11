module Legacy
  module Hrdb
    module CimHrdbStaff

      def self.included(base)
        base.class_eval do
          belongs_to :person
        end

        base.extend CimHrdbStaffClassMethods
      end

      def boolean_is_active
        case self.is_active
        when 1
          true
        when 0
          false
        end
      end

      module CimHrdbStaffClassMethods
        # This method will return the person id associated with a given staff id
        def find_person_id(staff_id)
          staff = find(:first, :conditions => {_(:id) => staff_id})
          staff ? staff["#{_(:person_id)}"] : nil
        end
      end

    end
  end
end
