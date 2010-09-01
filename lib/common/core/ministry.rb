class Ministry
  TYPES = [ "activity", "team", "region" ]
end

module Common
  module Core
    module Ministry
      def self.included(base)
        base.class_eval do
          set_inheritance_column "asdf"

          acts_as_nested_set

          # acts_as_tree :order => _(:name), :counter_cache => true
          
          has_many :permissions, :through => :ministry_roles, :source => :ministry_role_permissions
          # note - dependent is removed since these role methods are overridden
          #  to return the root ministry's roles as well, meaning the root ministry's
          #  roles were also being deleted!
          has_many :my_ministry_roles, :order => _(:position, :ministry_role), :class_name => "MinistryRole"
          has_many :my_student_roles, :order => _(:position, :ministry_role), :class_name => "StudentRole"
          has_many :my_staff_roles, :order => _(:position, :ministry_role), :class_name => "StaffRole"
          has_many :my_other_roles, :order => _(:position, :ministry_role), :class_name => "OtherRole"
          has_many :campus_involvements
          # has_many :people, :through => :campus_involvements
          has_many :people, :through => :ministry_involvements
          has_many :ministry_campuses, :include => :campus, :dependent => :destroy, :order => __(:name, :campus)
          has_many :campuses, :through => :ministry_campuses, :order => __(:name, :campus)
          has_many :ministry_involvements, :dependent => :destroy, :dependent => :destroy
          has_many :training_question_activations
          has_many :active_training_questions, :through => :training_question_activations, :source => :training_question
          
          validates_presence_of _(:name)
          
          validates_uniqueness_of _(:name), :scope => _(:parent_id)
          
          after_create :create_default_roles
          
          #alias_method :my_ministry_roles, :ministry_roles
          #alias_method :my_staff_roles, :staff_roles
          #alias_method :my_student_roles, :student_roles
          #alias_method :my_other_roles, :other_roles
          #alias_method :campus_ids, :campus_ids2
          
          # Create a default view for this ministry
          # Training categories including all the categories higher up on the tree
          # Training questions including all the questions higher up on the tree
          #protected
        
          def self.default_ministry
            return @default_ministry if @default_ministry.present?
            @default_ministry = ::Ministry.find(:first, :conditions => { :name => Cmt::CONFIG[:default_ministry_name] })
            @default_ministry ||= ::Ministry.first
          end
        end
      end

      def staff_involvements
        @staff_involvements ||= ministry_involvements.find(:all, 
            :conditions => [ "ministry_role_id in (?)", staff_role_ids ]
        )
      end

      def staff
        @staff ||= ::Person.find(:all, :conditions => ["#{_(:ministry_role_id, :ministry_involvement)} IN (?) AND #{_(:ministry_id, :ministry_involvement)} = ?", staff_role_ids, self.id], :joins => :ministry_involvements, :order => _(:first_name, :person))
      end
      
      def leaders
        @leaders ||= ::Person.find(:all, :conditions => ["#{_(:ministry_role_id, :ministry_involvement)} IN (?) AND #{_(:ministry_id, :ministry_involvement)} = ?", leader_role_ids, self.id], :joins => :ministry_involvements, :order => _(:first_name, :person))
      end
      
      def students
        @leaders ||= ::Person.find(:all, :conditions => ["#{_(:ministry_role_id, :ministry_involvement)} IN (?) AND #{_(:ministry_id, :ministry_involvement)} = ?", student_role_ids, self.id], :joins => :ministry_involvements, :order => _(:first_name, :person))
      end

      def ministry_roles
        self.root? ? my_ministry_roles : self.root.my_ministry_roles
      end
      
      def staff_roles
        self.root? ? my_staff_roles : self.root.my_staff_roles
      end
      
      def student_roles
        self.root? ? my_student_roles : self.root.my_student_roles
      end
      
      def other_roles
        self.root? ? my_other_roles : self.root.my_other_roles
      end
      
      def unique_campuses
        # it's faster to uniq this in rails than try to do it in sql
        ::Campus.all(:joins => :ministries, :conditions => descendants_condition).uniq
      end

      ##### replaced by subministry_campuses using the new nested set
      def unique_campuses_old
        unless @unique_campuses
          res =  lambda {::Campus.find(campus_ids)}
          @unique_campuses = (Rails.env.production? ? Rails.cache.fetch([self, 'unique_campuses']) {res.call} : res.call)
        end
        return @unique_campuses
      end
      
      def subministry_campuses(skip_self = true)
        conditions = descendants_condition
        conditions += " AND #{::MinistryCampus._(:ministry_id)} != #{self.id}" if skip_self
        ::MinistryCampus.all(:joins => :ministry, :conditions => "#{conditions}")
      end

      ##### replaced by subministry_campuses using the new nested set
      def subministry_campuses_old(top = true)
        unless @subministry_campuses
          @subministry_campuses = top ? [] : self.ministry_campuses
          self.children.each do |ministry|
            @subministry_campuses += ministry.subministry_campuses(false)
          end
        end
        return @subministry_campuses
      end
    
      def unique_ministry_campuses(skip_self = true)
        conditions = descendants_condition
        conditions += " AND #{::MinistryCampus._(:ministry_id)} != #{self.id}" if skip_self
        @unique_ministry_campuses ||= ::MinistryCampus.all(:joins => :ministry, :conditions => conditions)
        @unique_campuses = ::Campus.all(:joins => :ministries, :conditions => conditions).uniq
      end

      ##### replaced by subministry_campuses using the new nested set
      def unique_ministry_campuses_old(top = true)
        unless @unique_ministry_campuses
          res =  lambda {
            @unique_ministry_campuses = ministry_campuses.clone
            @unique_campuses = campuses.clone
            subministry_campuses(top).each do |mc|
              @unique_ministry_campuses << mc unless @unique_campuses.include?(mc.campus)
              @unique_campuses << mc.campus
            end
            @unique_ministry_campuses
          }
          @unique_ministry_campuses = (Rails.env.production? ? Rails.cache.fetch([self, 'unique_ministry_campuses']) {res.call} : res.call)
        end
        return @unique_ministry_campuses
      end
      
=begin
      def ancestors
        unless @ancestors
          @ancestors = parent ? [self, parent.ancestors] : [self]
          @ancestors.flatten!
        end
        @ancestors
      end
=end
      
      def ancestor_ids
        @ancestor_ids ||= self_and_ancestors.collect(&:id)
      end
      
      def campus_ids2_old # TODO: make this _old once awesome nested set is used everywhere
        unless @campus_ids
          res =  lambda {
            ministry_ids = self_plus_descendants.collect(&:id)
            sql = "SELECT #{_(:campus_id, :ministry_campus)} FROM #{::MinistryCampus.table_name} WHERE #{_(:ministry_id, :ministry_campus)} IN(#{ministry_ids.join(',')})"
            ActiveRecord::Base.connection.select_values(sql).collect(&:to_i).uniq
          }
          @campus_ids = Rails.env.production? ? Rails.cache.fetch([self, 'campus_ids']) {res.call} : res.call
        end
        @campus_ids
      end

      def myself_and_descendants() self_plus_descendants end
=begin
      def myself_and_descendants
        unless @myself_and_descendants
          @myself_and_descendants = [self] | descendants
        end
        return @myself_and_descendants
      end
=end

=begin
      def descendants
        unless @descendants
          @offspring = self.children.find(:all, :include => :children)
          @descendants = @offspring.dup
          @offspring.each do |ministry|
              @descendants += ministry.descendants unless ministry.children.length == 0 || ministry == self
            end
          @descendants.sort!
        end
        return @descendants
      end
=end
      
      def root
        @root ||= self.parent_id ? self.parent.root : self
      end
      
      def root?
        self.parent_id.nil?
      end
      
      def leader_roles
        @leader_roles ||= staff_roles
      end
      
      def leader_role_ids
        @leader_roles_ids ||= leader_roles.collect(&:id)
      end
      
      def staff_role_ids
        @staff_role_ids ||= staff_roles.find(:all).collect(&:id)
      end
      
      def student_role_ids
        @student_role_ids ||= student_roles.collect(&:id)
      end
      
      def involved_student_roles
        @involved_student_roles ||= ::StudentRole.find(:all, :conditions => { _(:involved, :ministry_roles) => true }, :order => _(:position, :ministry_roles))
      end
      
      def involved_student_role_ids
        @involved_student_role_ids ||= involved_student_roles.collect(&:id)
      end
      
      def self_plus_descendants
        res =  lambda {(self.descendants + [self]).sort}
        Rails.env.production? ? Rails.cache.fetch([self, 'self_plus_descendants']) {res.call} : res.call
      end
      
      def deleteable?
        !self.root? && self.children.count.to_i == 0
      end
      
      def <=>(ministry)
        self.name <=> ministry.name
      end
      
      def campus_to_hash(campus)
        base_hash = { 'text' => campus.campus_shortDesc, 'id' => "#{id}_#{campus.id}" , 'leaf' => true }
      end
      
      def leaf_merge(show_campuses)
        leaf_hash = {}
        if show_campuses && campuses.count > 1
          leaf_hash.merge!('expanded' => true, 
            'children' => campuses.collect{|c| campus_to_hash(c)})
        else
          leaf_hash.merge!('leaf' => true)
        end
        leaf_hash
      end
      
      def to_hash_with_children(show_campuses = false)
        base_hash = { 'text' => name, 'id' => id }
        if children.empty?
          base_hash.merge(leaf_merge(show_campuses))
        else
          base_hash.merge('expanded' => true, 
            'children' => children.collect{|c| c.to_hash_with_children(show_campuses)})
        end
      end

      def to_hash_with_only_the_children_person_is_involved_in(person, show_ministries_under_involvement = false)
        base_hash = { 'text' => name, 'id' => id }

        children_involved_in = children.select{|c| c.person_involved_at_or_under(person)}

        if children_involved_in.empty?
          if show_ministries_under_involvement && involved_ministries(person).include?(self) && !(children.empty?)
            base_hash.merge('expanded' => true, 
            'children' => children.collect{|c| c.to_hash_with_children(show_ministries_under_involvement)})
          else
            base_hash.merge(leaf_merge(show_ministries_under_involvement))
          end
        else
          base_hash.merge('expanded' => true,
            'children' => children_involved_in.collect{ |c| c.to_hash_with_only_the_children_person_is_involved_in(person, show_ministries_under_involvement) })
        end
      end

      def involved_ministries(person)
        person.ministry_involvements.collect{|mi| mi.ministry}
      end

      def person_involved_at_or_under(person)

        self.myself_and_descendants.each do |m|
          return true if involved_ministries(person).include?(m)
        end

        false
      end
      
      def before_destroy
        my_ministry_roles.each do |mr|
          mr.destroy
        end
      end
      
      def descendants_condition
        "#{__(:lft, :ministry)} >= #{lft} AND #{__(:rgt, :ministry)} <= #{rgt}"
      end

      def descendants_with_names
        ::Ministry.find(:all, :select => "#{::Ministry.__(:id)} as id, #{::Ministry.__(:name)} as name, parents_#{::Ministry.table_name.gsub('.','_')}.#{::Ministry._(:name)} as parent_name", :joins => "LEFT OUTER JOIN `uscm`.`sn_ministries` parents_uscm_sn_ministries ON `parents_uscm_sn_ministries`.id = `uscm`.`sn_ministries`.parent_id", :conditions => descendants_condition, :order => ::Ministry.__(:name))
      end

      def descendants_staff_count_hash
        return @descendants_staff_count_hash if @descendants_staff_count_hash
        ms = Ministry.find(:all, :select => "#{Ministry.__(:id)}, (COUNT(*)) as num_staff", :joins => "INNER JOIN #{MinistryInvolvement.table_name} ON #{MinistryInvolvement.__(:ministry_id)} = #{Ministry.__(:id)}", :conditions => self.descendants_condition + " AND ministry_role_id IN (#{self.staff_role_ids.join(',')})", :group => Ministry.__(:id))
        @descendants_staff_count_hash = Hash[ms.collect{ |m| [ m.id, m.num_staff ] }]
      end

      def descendants_groups_count_hash
        return @descendants_groups_count_hash if @descendants_groups_count_hash
        ms = Ministry.find(:all, :select => "#{Ministry.__(:id)}, (COUNT(*)) as num_groups", :joins => "INNER JOIN #{Group.table_name} ON #{Group.__(:ministry_id)} = #{Ministry.__(:id)}", :conditions => self.descendants_condition, :group => Ministry.__(:id))
        @descendants_groups_count_hash = Hash[ms.collect{ |m| [ m.id, m.num_groups ] }]
      end

      # TODO this should use the seed instead of recreating it inline here
      # Create a default view for this ministry
      # Training categories including all the categories higher up on the tree
      # Training questions including all the questions higher up on the tree
      protected
      
      # TODO this should use the seed instead of recreating it inline here
      def create_default_roles
        if self.root?
          self.ministry_roles << ::MinistryRole.create(_(:name, :ministry_role) => 'Campus Coordinator', _(:position, :ministry_role) => 2)
          self.ministry_roles << ::MinistryRole.create(_(:name, :ministry_role) => 'Ministry Leader', _(:position, :ministry_role) => 4, :description => 'a student who oversees a campus, eg LINC leader')
          self.ministry_roles << ::MinistryRole.create(_(:name, :ministry_role) => 'Missionary', _(:position, :ministry_role) => 3)
          self.ministry_roles << ::MinistryRole.create(_(:name, :ministry_role) => 'Student Leader', _(:position, :ministry_role) => 5)
          self.ministry_roles << ::MinistryRole.create(_(:name, :ministry_role) => 'Involved Student', _(:position, :ministry_role) => 6, :description => 'we are saying has been attending events for at least 6 months')
          self.ministry_roles << ::MinistryRole.create(_(:name, :ministry_role) => 'Student', _(:position, :ministry_role) => 7)
          self.ministry_roles << ::MinistryRole.create(_(:name, :ministry_role) => 'Registration Incomplete', _(:position, :ministry_role) => 8, :description => 'A leader has registered them, but user has not completed rego and signed the privacy policy')
          self.ministry_roles << ::MinistryRole.create(_(:name, :ministry_role) => 'Approval Pending', _(:position, :ministry_role) => 9, :description => 'They have applied, but a leader has not verified their application yet')
          self.ministry_roles << ::MinistryRole.create(_(:name, :ministry_role) => 'Honourary Member', _(:position, :ministry_role) => 10, :description => 'not a valid student or missionary, but we are giving them limited access anyway')
          self.ministry_roles << ::MinistryRole.create(_(:name, :ministry_role) => 'Admin', _(:position, :ministry_role) => 1)
        end
        true # otherwise subsequent after_create calls will fail
      end

    end
  end
end
