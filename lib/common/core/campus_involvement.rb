module Common
  module Core
    module CampusInvolvement
      def self.included(base)
        base.class_eval do

          validates_presence_of :campus_id, :person_id, :ministry_id, :school_year_id

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
        # look for the latest MC, under the assumption it will be the most nested
        # if staff start wanting to have staff-only groups with campuses, we'll have to
        # rethink this
        ministry_campus = ::MinistryCampus.find :last, :conditions => { :campus_id => campus_id }
        ministry_campus.try(:ministry)
      end

      def find_ministry_involvement
        return @ministry_involvement if @ministry_involvement
        @derived_ministry = derive_ministry || Cmt::CONFIG[:default_ministry] || ::Ministry.first
        @ministry_involvement = @derived_ministry.ministry_involvements.find :first, :conditions => [ "person_id = ? AND end_date IS NULL", person_id ]
      end

      def find_or_create_ministry_involvement
        return @ministry_involvement if @ministry_involvement
        mi = find_ministry_involvement
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
    end
  end
end
