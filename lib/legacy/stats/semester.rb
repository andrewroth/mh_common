module Legacy
  module Stats
    module Semester

      def self.included(base)
        base.class_eval do
          has_many :prcs, :class_name => 'Prc', :foreign_key => _(:semester_id, :prc)
          has_many :weeks, :class_name => 'Week', :foreign_key => _(:semester_id, :week)
          has_many :months, :class_name => 'Month', :foreign_key => _(:semester_id, :month)
          has_many :semester_reports, :class_name => 'SemesterReport'
          belongs_to :year, :class_name => 'Year'
        end

        base.extend SemesterClassMethods
      end

      def evaluate_stat(campus_ids, stat_hash, staff_id = nil)
        #debugger if staff_id == 336 && stat_hash[:column] == :weeklyReport_1on1HsPres
        evaluation = 0
        if stat_hash[:column_type] == :database_column
          if stat_hash[:collected] == :semesterly
            evaluation = find_stats_semester_campuses(campus_ids, stat_hash[:column])
          elsif stat_hash[:collected] == :monthly
            evaluation = find_monthly_stats_campuses(campus_ids, stat_hash[:column])
          elsif stat_hash[:collected] == :weekly
            evaluation = find_weekly_stats_campuses(campus_ids, stat_hash[:column], staff_id)
          elsif stat_hash[:collected] == :prc
            evaluation = find_prcs_campuses(campus_ids)
          end
        end
        evaluation
      end

      def find_stats_semester_campuses(campus_ids, stat)
        #semester_reports.sum(_(stat, :semester_report), :conditions => ["#{_(:campus_id, :semester_report)} IN (?)", campus_ids])
        result = get_stat_sums_for(campus_ids)["#{stat}"]
        result.nil? ? 0 : result
      end

      def find_weekly_stats_campuses(campus_ids, stat, staff_id = nil)
        #debugger if staff_id == 336 && stat == :weeklyReport_1on1HsPres
        total = 0
        weeks.each { | week | total += week.sum_stat_for_campuses(campus_ids, stat, staff_id) }
        total
      end

      def find_monthly_stats_campuses(campus_ids, stat)
        total = 0
        months.each { | month | total += month.find_monthly_stats_campuses(campus_ids, stat) }
        total
      end

      def find_prcs_campuses(campus_ids)
        prcs.count(:all, :conditions => ["#{_(:campus_id, :prc)} IN (?)", campus_ids])
      end

      def get_database_columns(report)
        stats_reports[report].collect{|k, c| c[:column_type] == :database_column ? c[:column] : nil}.compact
      end
      
      def get_semester_report_columns
        @monthly_report_columns ||= get_database_columns(:semester_report)
      end

      def get_hash(campus_ids)
        campus_ids.nil? ? "nil" : campus_ids.hash
      end

      def get_stat_sums_for(campus_ids)
        @result_sums ||= Hash.new
        @result_sums[get_hash(campus_ids)] ||= execute_stat_sums_for(campus_ids)
      end

      def execute_stat_sums_for(campus_ids)
        select = get_semester_report_columns.collect{|c| "sum(#{c}) as #{c}"}.join(', ')
        conditions = []
        conditions += ["#{_(:campus_id, :semester_report)} IN (#{campus_ids.join(',')})"] unless campus_ids.nil?
        semester_reports.find(:all, :select => select, :conditions => [conditions.join(' AND ')]).first
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
