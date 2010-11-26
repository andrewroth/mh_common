module Common
  module Core
    module CampusInvolvement
      def self.included(base)
        base.class_eval do

          validates_presence_of :campus_id, :person_id, :ministry_id

          belongs_to :school_year
          belongs_to :campus
          belongs_to :person
          belongs_to :ministry
          belongs_to :added_by, :class_name => "Person", :foreign_key => _(:added_by_id)
          has_many :student_involvement_histories
        end
      end

      def validate
        if !archived?
          if (ci = ::CampusInvolvement.find(:first, :conditions => { :person_id => person_id, :campus_id => campus_id, :end_date => nil })) && (ci != self)
            errors.add_to_base "There is already a campus involvement for the campus \"#{campus.name}\"; you can only be involved once per campus.  Archive the existing involvement and try again."
          end
        end
      end

      def archived?() end_date.present? end

      def derive_ministry
        campus.try(:derive_ministry)
      end

      def find_ministry_involvement
        return @ministry_involvement if @ministry_involvement
        @derived_ministry = derive_ministry || Cmt::CONFIG[:default_ministry] || ::Ministry.first
        @ministry_involvement = @derived_ministry.ministry_involvements.find :first, :conditions => [ "person_id = ? AND end_date IS NULL", person_id ]
      end

      def find_or_create_ministry_involvement
        return @ministry_involvement if @ministry_involvement
        mi = find_ministry_involvement # TODO: this depends on a side effect of @derived_ministry ; refactor line that sets @derived_ministry to get_derived_ministry and use get_derived_minsitry here.
        if mi.nil?
          mi = @derived_ministry.ministry_involvements.create :person => person, :ministry_role => ::MinistryRole.default_student_role
        elsif mi.ministry_role_id.nil?
          mi.ministry_role_id = ::MinistryRole.default_student_role.id
          mi.save
        elsif !mi.try(:ministry_role).is_a?(::StudentRole)
          mi.ministry_role_id = ::MinistryRole.default_student_role.id
          logger.info "Making person #{mi.person.id} (#{mi.person.full_name}) ministry involvement #{mi.inspect} to a student role.  Trace: #{caller.join("\n")}"
        end
        @ministry_involvement = mi
      end

      def new_student_history
        ::StudentInvolvementHistory.new :person_id => person_id, :campus_id => campus_id, :school_year_id => school_year_id, :end_date => Date.today, :ministry_role_id => find_or_create_ministry_involvement.ministry_role_id, :start_date => (last_history_update_date || start_date), :campus_involvement_id => id
      end

      def update_student_campus_involvement(flash, my_role, ministry_role_id, school_year_id, campus_id)
        @campus_ministry_involvement = self.find_or_create_ministry_involvement

        # restrict students to making ministry involvements of their role or less
        if ministry_role_id && ministry_role_id != :same
          requested_role = ::MinistryRole.find(ministry_role_id) || ::MinistryRole.default_student_role
          ministry_role_id = requested_role.id

          # note that get_my_role sets @ministry_involvement as a side effect
          if !(my_role.is_a?(::StaffRole) && requested_role.is_a?(::StudentRole)) &&
            requested_role.position < get_my_role.position
            flash[:notice] = "You can only set ministry roles of less than or equal to your current role"
            ministry_role_being_updated = false
            ministry_role_id = @campus_ministry_involvement.ministry_role_id.to_s
          end
        elsif ministry_role_id == :same
          ministry_role_id = @campus_ministry_involvement.ministry_role_id
        else
          ministry_role_id = ::MinistryRole.default_student_role.id
        end

        # record history
        record_history = !self.new_record? &&
          (self.school_year_id.to_s != school_year_id.to_s ||
           @campus_ministry_involvement.ministry_role_id.to_s != ministry_role_id.to_s ||
           self.campus_id.to_s != campus_id.to_s)
        if record_history
          @history = self.new_student_history
          @history.ministry_role_id = @campus_ministry_involvement.ministry_role_id
        end

        # update the records
        self.update_attributes :school_year_id => school_year_id,
          :campus_id => campus_id
        if ministry_role_being_updated # update role
          @campus_ministry_involvement.ministry_role = requested_role
          @campus_ministry_involvement.save!
        end
        if record_history && self.errors.empty? && @campus_ministry_involvement.errors.empty?
          @history.save!
          self.update_attributes :last_history_update_date => Date.today
        end
      end
    end
  end
end
