module Common
  module Core
    module Ministry
      def self.included(base)
        base.class_eval do
          # acts_as_tree :order => _(:name), :counter_cache => true
          has_many :children, :class_name => "Ministry", :foreign_key => _(:parent_id), 
            :order => "#{::Ministry.table_name}.`#{_(:ministries_count)}` DESC, #{::Ministry.table_name}.`#{_(:name)}"
          
          belongs_to :parent, :class_name => "Ministry", :foreign_key => _(:parent_id),
            :counter_cache => :ministries_count
          
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
          has_many :ministry_campuses, :include => :campus, :dependent => :destroy, :order => ::Campus.table_name + '.' + _(:name, :campus)
          has_many :campuses, :through => :ministry_campuses, :order => _(:name, 'campus')
          has_many :ministry_involvements, :dependent => :destroy, :dependent => :destroy
          has_many :training_question_activations
          has_many :active_training_questions, :through => :training_question_activations, :source => :training_question
          has_many :group_types
          
          
          validates_presence_of _(:name)
          
          validates_uniqueness_of _(:name), :scope => _(:parent_id)
          
          after_create :create_default_roles
          
          #alias_method :my_ministry_roles, :ministry_roles
          #alias_method :my_staff_roles, :staff_roles
          #alias_method :my_student_roles, :student_roles
          #alias_method :my_other_roles, :other_roles
          alias_method :campus_ids, :campus_ids2
          
          # Create a default view for this ministry
          # Training categories including all the categories higher up on the tree
          # Training questions including all the questions higher up on the tree
          #protected
        
          # TODO this should use the seed instead of recreating it inline here
        end
      end

      def staff
        @staff ||= ::Person.find(:all, :conditions => ["#{_(:ministry_role_id, :ministry_involvement)} IN (?) AND #{_(:ministry_id, :ministry_involvement)} = ?", staff_role_ids, self.id], :joins => :ministry_involvements, :order => _(:first_name, :person))
      end
      
      def leaders
        @leaders ||= ::Person.find(:all, :conditions => ["#{_(:ministry_role_id, :ministry_involvement)} IN (?) AND #{_(:ministry_id, :ministry_involvement)} = ?", leader_role_ids, self.id], :joins => :ministry_involvements, :order => _(:first_name, :person))
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
        unless @unique_campuses
          res =  lambda {::Campus.find(campus_ids)}
          @unique_campuses = (Rails.env.production? ? Rails.cache.fetch([self, 'unique_campuses']) {res.call} : res.call)
        end
        return @unique_campuses
      end
      
      def subministry_campuses(top = true)
        unless @subministry_campuses
          @subministry_campuses = top ? [] : self.ministry_campuses
          self.children.each do |ministry|
            @subministry_campuses += ministry.subministry_campuses(false)
          end
        end
        return @subministry_campuses
      end
    
      def unique_ministry_campuses(top = true)
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
      
      def ancestors
        unless @ancestors
          @ancestors = parent ? [self, parent.ancestors] : [self]
          @ancestors.flatten!
        end
        @ancestors
      end
      
      def ancestor_ids
        @ancestor_ids ||= ancestors.collect(&:id)
      end
      
      def campus_ids2
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

      def myself_and_descendants
        unless @myself_and_descendants
          @myself_and_descendants = [self] | descendants
        end
        return @myself_and_descendants
      end

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
      
      def to_hash_with_children
        base_hash = { 'text' => name, 'id' => id }
        if children.empty?
          base_hash.merge('leaf' => true)
        else
          base_hash.merge('expanded' => true, 
            'children' => children.collect(&:to_hash_with_children))
        end
      end

      def to_hash_with_only_children_person_involved_in(person)
        base_hash = { 'text' => name, 'id' => id }

        children_involved_in = children.select{|c| c.person_involved_at_or_under(person)}

        if children_involved_in.empty?
          base_hash.merge('leaf' => true)
        else
          base_hash.merge('expanded' => true,
            'children' => children_involved_in.collect{ |c| c.to_hash_with_only_children_person_involved_in(person) })
        end
      end

      def person_involved_at_or_under(person)
        involved_ministries = person.ministry_involvements.collect{|mi| mi.ministry}

        self.myself_and_descendants.each do |m|
          return true if involved_ministries.include?(m)
        end

        false
      end
      
      def before_destroy
        my_ministry_roles.each do |mr|
          mr.destroy
        end
      end
      
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
