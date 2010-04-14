module Common
  module Core
    module Ca
      module MinistryRole
        def self.included(base)
          base.extend MinistryRoleClassMethods
        end
      end

      module MinistryRoleClassMethods

        def ministry_roles_that_grant_stats_access
          role_ids = ::MinistryRolePermission.all(:joins => :permission, :conditions => ["#{::Permission.table_name}.controller = ? AND #{::Permission.table_name}.action = ?", "stats", "index"]).collect{ |mrp| mrp.ministry_role_id }
          ::MinistryRole.all(:conditions => ["id IN(?)", role_ids])
        end

      end

    end
  end
end
