module Legacy
  module Stats
    module Month

      def self.included(base)
        base.class_eval do
          has_many :monthly_reports, :class_name => 'MonthlyReport', :foreign_key => _(:month_id, :monthly_report)
          belongs_to :year, :class_name => 'Year'
          belongs_to :semester, :class_name => 'Semester'
          has_many :weeks, :class_name => 'Week', :foreign_key => _(:month_id, :week)
          default_scope :order => "month_literalyear ASC, month_number ASC"
        end

        base.extend StatsClassMethods
      end

      def stats_available
        [:monthly, :weekly, :prc]
      end

      def reports_associated
        [:monthly_report, :monthly_p2c_special]
      end

#########################################################################################
# Stuff to move eventually in a common module or base class
#########################################################################################

      def get_database_columns(report, grouping_method)
        stats_reports[report].collect{|k, c| (c[:column_type] == :database_column && c[:grouping_method] == grouping_method ) ? c[:column] : nil}.compact
      end

      def get_columns(grouping_method)
        unless @get_summable_columns
          @get_summable_columns = []
          reports_associated.each do |ra|
            @get_summable_columns += get_database_columns(ra, grouping_method)
          end
        end
        @get_summable_columns
      end

#########################################################################################

      def evaluate_stat(campus_ids, stat_hash, staff_id = nil)
        evaluation = 0
        if stat_hash[:column_type] == :database_column
          if stat_hash[:collected] == :monthly
            evaluation = find_monthly_stats_campuses(campus_ids, stat_hash)
          elsif stat_hash[:collected] == :weekly
            evaluation = find_weekly_stats_campuses(campus_ids, stat_hash, staff_id)
          elsif stat_hash[:collected] == :prc
            evaluation = find_prcs_campuses(campus_ids)
          end
        end
        evaluation
      end

      def run_weekly_stats_request(campus_ids, staff_id = nil)
        @weekly_sums ||= {}        
        @weekly_sums[get_hash(campus_ids, staff_id)] ||= ::WeeklyReport.get_weekly_stats_sums_over_period(self, campus_ids, staff_id)        
      end
      
      def no_weekly_data(campus_ids, staff_id = nil)
        stat = ''
        stats_reports[:weekly_report].each do |k,v|
          if v[:column_type] == :database_column
            stat = v[:column]
            break
          end
        end
        run_weekly_stats_request(campus_ids, staff_id)[stat].nil? ? true : false
      end
      
      def find_weekly_stats_campuses(campus_ids, stat_hash, staff_id = nil)
        result = nil
        
        if stat_hash[:grouping_method] == :last_non_zero
          result = ::WeeklyReport.get_last_non_zero_weekly_stats_over_period(self, stat_hash[:column], campus_ids, staff_id)
        else
          result = run_weekly_stats_request(campus_ids, staff_id)[stat_hash[:column]]
        end
        
        result.nil? ? 0 : result
      end

      def find_monthly_stats_campuses(campus_ids, stat_hash)
        result = nil
        
        if stat_hash[:grouping_method] == :last_non_zero
          result = get_last_non_zero(campus_ids, stat_hash)
        else
          result = get_stat_sums_for(campus_ids)["#{stat_hash[:column]}"]
        end
        
        result.nil? ? 0 : result
      end

      def get_last_non_zero(campus_ids, stat_hash)
        sum_campus = 0
        campus_ids.each do |c_id|
          new_result = monthly_reports.find(:last, :conditions => ["campus_id = #{c_id} AND #{stat_hash[:column]} <> 0"])
          sum_campus += new_result[stat_hash[:column]] unless new_result.nil?
        end
        sum_campus
      end

      def start_date
        Time.local(calendar_year, number, 1)
      end

      def end_date
        is_leap =
          case
          when calendar_year % 400 == 0
              true
          when calendar_year % 100 == 0
              false
          else
              calendar_year % 4 == 0
          end
        
        end_day_hash = { 1 => 31, 2 => is_leap ? 29 : 28, 3 => 31,
                         4 => 30, 5 => 31, 6 => 30, 7 => 31, 8 => 31,
                         9 => 30, 10 => 31, 11 => 30, 12 => 31}
        Time.local(calendar_year, number, end_day_hash[number])
      end

      def find_prcs_campuses(campus_ids)
        str_month = "#{number}".rjust(2, "0")
        start_date = "#{calendar_year}-#{str_month}-00"
        end_date = "#{calendar_year}-#{str_month}-31"
        semester.prcs.count(:all, :conditions => ["#{_(:campus_id, :prc)} IN (?) AND #{_(:date, :prc)} > '#{start_date}' AND #{_(:date, :prc)} <= '#{end_date}'", campus_ids])#, :conditions => ["#{_(:campus_id)} IN (?)",campus_ids])
      end
      
      def get_hash(campus_ids, staff_id = nil)
        [campus_ids.nil? ? nil : campus_ids.hash, staff_id].compact.join("_")
      end

      def get_stat_sums_for(campus_ids)
        @result_sums ||= Hash.new
        @result_sums[get_hash(campus_ids)] ||= execute_stat_sums_for(campus_ids)
      end

      def execute_stat_sums_for(campus_ids)
        select = get_columns(:sum).collect{|c| "sum(#{c}) as #{c}"}.join(', ')
        conditions = []
        conditions += ["#{_(:campus_id, :monthly_reports)} IN (#{campus_ids.join(',')})"] unless campus_ids.nil?
        unless conditions.empty?
          monthly_reports.find(:all, :select => select, :conditions => [conditions.join(' AND ')]).first
        else
          monthly_reports.find(:all, :select => select).first
        end
       end


      module StatsClassMethods
        # This method will return the start date of a given month id
        def find_start_date(month_id)
          result = find(:first, :select => "#{_(:number)}, #{_(:calendar_year)}", :conditions => {_(:id) => month_id} )
          monthNum = result.number
          curYear = result.calendar_year
          # Return it in string format
          startdate = "#{curYear}-#{monthNum}-#{00}" # Note: 00 is what we want.
          startdate
        end
  
        # This method will return the end date of a given month id
        def find_end_date(month_id)
          result = find(:first, :select => "#{_(:number)}, #{_(:calendar_year)}", :conditions => {_(:id) => month_id} )
          monthNum = result.number
          curYear = result.calendar_year
          # Return it in string format
          enddate = "#{curYear}-#{monthNum}-#{31}" # Note: 31 is what we want even though not all months have 31 days.
          enddate
        end

        # This method will return the year id associated with a given month description
        def find_year_id(description)
          find(:first, :conditions => {_(:description) => description})["#{_(:year_id)}"]
        end

        # This method will return the month id associated with a given description
        def find_month_id(description)
          find(:first, :conditions => {_(:description) => description}).id
        end

        # This method will return the month description associated with a given id
        def find_month_description(id)
          find(:first, :conditions => {_(:id) => id}).description
        end

        # This method will return the semester id associated with a given month description
        def find_semester_id(description)
          find(:first, :conditions => {_(:description) => description})["#{_(:semester_id)}"]
        end

        # This method will return all the months associated with a given semester id
        def find_months_by_semester(semester_id)
          find(:all, :conditions => { _(:semester_id) => semester_id }, :order => _(:id))
        end

        # This method will return an array of all the months leading up to and including the current month id
        def find_months(current_id)
          find(:all, :conditions => ["#{_(:id)} <= ?",current_id]).collect{ |m| [m.description]}
        end

        # return the month that the date belongs to
        #   if for_week = true will take into account that weeks with more days in the previous month belong to that month
        def find_month_from_date(date, for_week = false)
          date = Date.parse(date.to_s)

          # Saturday is day 6 of the week, week end dates are always Saturdays
          if for_week == true && date.wday == 6 && date.day <= 3
            date = date << 1 # get the previous month
          end

          months = ::Month.all(:conditions => {_(:description) => "#{Date::MONTHNAMES[date.month]} #{date.year}"})
          months.any? ? months.first : nil
        end
      end

    end
  end
end
