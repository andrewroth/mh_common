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
        ::StaffInvolvementHistory.new :person_id => person_id, :end_date => Date.today, :ministry_role_id => ministry_role_id, :start_date => (last_history_update_date || start_date), :ministry_involvement_id => id, :ministry_id => ministry_id
      end

      module MinistryInvolvementMethods

        # This method appears to be in the c4c.* branches but not utopian.  If that's the case,
        # it should be in Common::Core::Ca::MinistryInvolvement module, not here. -AR June 18, 2010
        def build_highest_ministry_involvement_possible(person = nil)
          mi = ::MinistryInvolvement.new
          mi.person_id = person.nil? ? nil : person.id
          mi.ministry_id = 1
          mi.start_date = Date.today
          mi.admin = 1
          mi.ministry_role_id = ::StaffRole.find(:first, :order => :position).id
          mi
        end

      end

    end
  end
end
