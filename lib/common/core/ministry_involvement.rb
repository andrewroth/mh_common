module Common
  module Core
    module MinistryInvolvement
      def self.included(base)
        base.class_eval do
          load_mappings
          
          belongs_to :responsible_person, :class_name => "Person"
          belongs_to :person, :class_name => "Person", :foreign_key => _(:person_id)
          belongs_to :ministry
          belongs_to :ministry_role, :class_name => "MinistryRole", :foreign_key => _("ministry_role_id")
          has_many :permissions, :through => :ministry_role, :source => :ministry_role_permissions
          has_many :staff_involvement_histories
          
          validates_presence_of _(:ministry_role_id), :on => :create, :message => "can't be blank"
          validates_presence_of _(:ministry_id)
        end

        base.extend MinistryInvolvementMethods
      end

      def validate
        if !archived?
          if (mi = ::MinistryInvolvement.find(:first, :conditions => { :person_id => person_id, :ministry_id => ministry_id, :end_date => nil })) && (mi != self)
            errors.add_to_base "There is already a ministry involvement for the ministry \"#{ministry.try(:name)}\"; you can only be involved once per ministry.  Archive the existing involvement and try again."
          end
        end
      end
    
      def archived?() end_date.present? end

      def new_staff_history
        new_history
      end

      def new_history
        if ministry_role.class == ::StaffRole
          ::StaffInvolvementHistory.new   :person_id => person_id, :end_date => (end_date || Date.today), :ministry_role_id => ministry_role_id,
                                          :start_date => (last_history_update_date || start_date), :ministry_involvement_id => id, :ministry_id => ministry_id

        elsif ministry_role.class == ::StudentRole
          ::StudentInvolvementHistory.new :person_id => person_id, :end_date => (end_date || Date.today), :ministry_role_id => ministry_role_id,
                                          :start_date => (last_history_update_date || start_date), :ministry_involvement_id => id, :ministry_id => ministry_id
        end
      end

      def update_ministry_role_and_history(ministry_role_id)
        save_history = self.ministry_role_id.to_s != ministry_role_id.to_s
        history = self.new_history if save_history
        
        self.end_date = nil if self.archived?

        self.ministry_role_id = ministry_role_id
        self.last_history_update_date = Date.today
        if self.save!
          history.save if save_history
        end

        history
      end

      def demote_staff_to_student(new_student_role_id)
        return unless self.ministry_role.class == ::StaffRole

        new_role = ::MinistryRole.first(:conditions => {:id => new_student_role_id})
        return unless new_role.class == ::StudentRole

        staff_ministry_involvements = ::MinistryInvolvement.all(:include => [:ministry_role], :conditions => {:person_id => self.person.id, :ministry_roles => {:type => ::StaffRole.to_s}})

        # end all staff involvements
        staff_ministry_involvements.each do |staff_ministry_involvement|
          unless staff_ministry_involvement.ministry.id == self.ministry.id
            history = staff_ministry_involvement.new_history
            staff_ministry_involvement.end_date = Date.today
            history.save if staff_ministry_involvement.save!
          else
            # change the involvement at the relevant ministry to the new student type role
            staff_ministry_involvement.update_ministry_role_and_history(new_role.id)
          end
        end
      end

      module MinistryInvolvementMethods

      end

    end
  end
end
