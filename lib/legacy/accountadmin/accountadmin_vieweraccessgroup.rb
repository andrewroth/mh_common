module Legacy
  module Accountadmin
    module AccountadminVieweraccessgroup

      def self.included(base)
        base.class_eval do
          belongs_to :accountadmin_accessgroup, :foreign_key => :accessgroup_id, :class_name => 'AccountadminAccessgroup'
          belongs_to :user, :foreign_key => :viewer_id, :class_name => 'User'
        end
      end

      module AccountadminVieweraccessgroupClassMethods
        # This method will return all the access ids associated with a given viewer id
        def find_access_ids(viewer_id)
          find(:all, :select => _(:accessgroup_id), :conditions => {_(:viewer_id) => viewer_id})
        end
      end

    end
  end
end
