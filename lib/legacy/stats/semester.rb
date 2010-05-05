module Legacy
  module Stats
    module Semester

      def self.included(base)
        base.class_eval do
          has_many :prcs, :class_name => 'Prc', :foreign_key => _(:semester_id, :prc)
          has_many :weeks, :class_name => 'Week', :foreign_key => _(:semester_id, :week)
          has_many :semester_reports, :class_name => 'SemesterReport'
          belongs_to :year, :class_name => 'Year'
        end

        base.extend SemesterClassMethods
      end

      def find_stats_semester_campuses(campuses, stat)
        campus_ids = campuses.collect {|c| c.id}
        semester_reports.sum(_(stat, :semester_report), :conditions => ["#{_(:campus_id, :semester_report)} IN (?)", campus_ids])
      end



      module SemesterClassMethods

        # This method will return the semester id associated with a given description
        def find_semester_id(description)
          find(:first, :conditions => {_(:description) => description}).id
        end

        # This method will return the semester description associated with a given id
        def find_semester_description(id)
          find(:first, :conditions => {_(:id) => id}).description
        end

        # This method will return an array of all semesters up to and including the current semester
        def find_semesters(current_id)
          find(:all, :conditions => ["#{_(:id)} <= ?",current_id]).collect{ |s| [s.description]}
        end

        # This method will return the start date of a given semester id
        def find_start_date(semester_id)
          find(:first, :conditions => {_(:id) => semester_id} ).semester_startDate
        end

        # This method will return the end date of a given semester id
        def find_end_date(semester_id)
          find(:first, :conditions => {_(:id) => (semester_id+1)} ).semester_startDate
        end

        # This method will return all the semesters associated with a given year
        def find_semesters_by_year(year_id)
          find(:all, :conditions => {_(:year_id) => year_id})
        end

        # This method will return the year id of a given semester id
        def find_semester_year(semester_id)
          find(:first, :conditions => {_(:id) => semester_id})["#{_(:year_id)}"]
        end

        # return the semester that the date belongs to
        #   if for_week = true will take into account that weeks with more days in the previous semester belong to that semester
        def find_semester_from_date(date, for_week = false)
          date = Date.parse(date.to_s)

          # months 1, 5, and 9 are the beginning of semesters
          # Saturday is day 6 of the week, week end dates are always Saturdays
          if for_week == true && date.wday == 6 && date.day <= 3 && (date.month == 1 || date.month == 5 || date.month == 9)
            date = date << 1 # get the previous month
          end

          semesters = all(:conditions => ["#{_(:start_date)} <= ?", date], :order => "#{_(:start_date)} asc")

          return semesters.empty? ? ::Semester.first : semesters.last
        end

      end
    end
  end
end
