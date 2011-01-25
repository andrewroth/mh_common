module Common
  module Core
    module MinistryRole
      def self.included(base)
        base.class_eval do
          acts_as_list :scope => :ministry
          
          belongs_to :ministry
          has_many :ministry_role_permissions
          has_many :permissions, :through => :ministry_role_permissions
          has_many :ministry_involvements
          has_many :people, :through => :ministry_involvements
          
          validates_presence_of :name, :ministry_id, :type
        end
        base.extend MinistryRoleClassMethods
      end

      def <=>(other)
        self.position <=> other.position
      end
      
      def >=(other)
        self.position <= other.position
      end

      # returns -1 if self is lower than other_role
      #          1 if self is higher than other_role
      #          0 if equal
      # (position 1 is higher than position 2)
      def compare_class_and_position(other_role)
        result = -1

        if self.class != other_role.class
          if self.class == ::StaffRole && other_role.class == ::StudentRole
            result = 1
          elsif self.class == ::StudentRole && other_role.class == ::StaffRole
            result = -1
          end

        else # roles have same class
          if self.position > other_role.position # (a lower position number is a higher position)
            result = -1
          elsif self.position < other_role.position
            result = 1
          elsif self.position == other_role.position
            result = 0
          end
        end

        result
      end
    end
    
    module MinistryRoleClassMethods
      def human_name
        self.name.underscore.humanize
      end

      def human_name_plural
        self.name.underscore.humanize.pluralize
      end
    
      def default_student_role
        sr = ::StudentRole.find_by_name %w(Student student)
        sr ||= ::StudentRole.find :last, :order => "position"
      end
    
      def default_staff_role
        sr = ::StaffRole.find_by_name %w(Missionary missionary Staff staff)
        sr ||= ::StaffRole.find :last, :order => "position"
      end

      # roles that person can promote others up to, from a lower role
      def promotable_roles(person, ministry)
          roles = []

          # get person's involvements at ministry or ministries above ministry
          my_involvements_at_ministry_or_above = person.ministry_involvements.all(:conditions => ["#{::MinistryInvolvement.__(:ministry_id)} IN (?)", ministry.ancestor_ids])

          unless my_involvements_at_ministry_or_above.blank?
            # get person's highest ministry role in these involvements
            my_involvements_at_ministry_or_above.sort!{|a,b| b.ministry_role.compare_class_and_position(a.ministry_role)} # sort by highest ministry role first (e.g. team leader is higher than team member)
            my_role_at_ministry = ::MinistryRole.find(my_involvements_at_ministry_or_above.first.ministry_role_id)
            
            if my_role_at_ministry.class == ::StaffRole
              roles += ::MinistryRole.all(:conditions => ["(#{::MinistryRole.__(:position)} >= ? AND #{::MinistryRole.__(:type)} = 'StaffRole') OR
                                                            #{::MinistryRole.__(:type)} = 'StudentRole'", my_role_at_ministry.position])
            elsif my_role_at_ministry.class == ::StudentRole
              roles += ::MinistryRole.all(:conditions => ["#{::MinistryRole.__(:position)} >= ? AND #{::MinistryRole.__(:type)} = 'StudentRole'", my_role_at_ministry.position])
            end
          end
          roles
      end

      # roles that person can demote others from, to a lower role
      def demotable_roles(person, ministry)
          roles = []

          # get person's involvements at ministry or ministries above ministry
          my_involvements_at_ministry_or_above = person.ministry_involvements.all(:conditions => ["#{::MinistryInvolvement.__(:ministry_id)} IN (?)", ministry.ancestor_ids])

          unless my_involvements_at_ministry_or_above.blank?
            # get person's highest ministry role in these involvements
            my_involvements_at_ministry_or_above.sort!{|a,b| b.ministry_role.compare_class_and_position(a.ministry_role)} # sort by highest ministry role first (e.g. team leader is higher than team member)
            my_role_at_ministry = ::MinistryRole.find(my_involvements_at_ministry_or_above.first.ministry_role_id)

            roles += promotable_roles(person, ministry)
            roles -= [my_role_at_ministry]
          end
          roles
      end
    end
  end
end
