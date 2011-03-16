module Legacy
  module Stats
    module Year

      def self.included(base)
        base.class_eval do
          has_many :months, :class_name => 'Month', :foreign_key => _(:year_id, :month)
          has_many :semesters, :class_name => 'Semester', :foreign_key => _(:year_id, :semester)
          has_many :annual_goals_reports, :class_name => 'AnnualGoalsReport'
          has_many :annual_reports, :class_name => 'AnnualReport'
          has_many :summer_reports, :class_name => 'SummerReport'
          has_many :summer_report_summer_definitions, :class_name => 'SummerReportSummerDefinition'
        end

        base.extend YearClassMethods
      end

      def start_date
        months.first.start_date
      end
      
      def end_date
        months.last.end_date
      end

      def stats_available
        [:yearly, :semesterly, :monthly, :weekly, :prc]
      end

      def evaluate_stat(campus_ids, stat_hash, staff_id = nil)
        total = 0
        if stat_hash[:column_type] == :database_column
          if stat_hash[:collected] == :yearly
            total = find_stats_year_campuses(campus_ids, stat_hash[:column])
          elsif stat_hash[:collected] == :weekly
            total = find_weekly_stats_campuses(campus_ids, stat_hash, staff_id)
          else
            if stat_hash[:grouping_method] == :last_non_zero
              total = find_stats_lnz_year_campuses(campus_ids, stat_hash[:column])
            else          
              semesters.each { | semester | total += semester.evaluate_stat(campus_ids, stat_hash, staff_id) }
            end
          end
        end
        total
      end

      def find_stats_year_campuses(campus_ids, stat)
        result = get_stat_sums_for(campus_ids)["#{stat}"]
        result.nil? ? 0 : result
      end

      def find_stats_lnz_year_campuses(campus_ids, stat)
        result = get_stat_lnz_for(campus_ids)[stat]
        result = result.nil? ? 0 : result
        result.to_i
      end


      def get_database_columns(report)
        stats_reports[report].collect{|k, c| c[:column_type] == :database_column ? c[:column] : nil}.compact
      end
      
      def get_annual_goal_report_columns
        @annual_goal_report_columns ||= get_database_columns(:annual_goals_report)
      end

      def get_stat_sums_for(campus_ids)
        @result_sums ||= Hash.new
        @result_sums[get_hash(campus_ids)] ||= execute_stat_sums_for(campus_ids)
      end

      def execute_stat_sums_for(campus_ids)
        select = get_annual_goal_report_columns.collect{|c| "sum(#{c}) as #{c}"}.join(', ')
        conditions = []
        conditions += ["#{_(:campus_id, :annual_goals_report)} IN (#{campus_ids.join(',')})"] unless campus_ids.nil?
        unless conditions.empty?
          annual_goals_reports.find(:all, :select => select, :conditions => [conditions.join(' AND ')]).first
        else
          annual_goals_reports.find(:all, :select => select).first
        end
      end

      def get_lnz_lines
        @lnz_lines ||= stats_reports.collect{|sr| sr[1].collect{|sc| sc[1][:grouping_method] == :last_non_zero ? sc[1] : nil}}.flatten.compact
      end

      def get_stat_lnz_for(campus_ids)
        @result_lnz ||= Hash.new
        @result_lnz[get_hash(campus_ids)] ||= execute_stat_lnz_for(campus_ids)
      end

      def execute_stat_lnz_for(campus_ids)
        res = nil
        select = get_lnz_lines.collect{|c| "sum(#{c[:lnz_correspondance][:annual_report]}) as #{c[:column]}"}.join(', ')
        conditions = []
        conditions += ["#{_(:campus_id, :annual_report)} IN (#{campus_ids.join(',')})"] unless campus_ids.nil?
        unless conditions.empty?
          res = annual_reports.find(:all, :select => select, :conditions => [conditions.join(' AND ')]).first
        else
          res = annual_reports.find(:all, :select => select).first
        end
        final = {}
        get_lnz_lines.each{|c| final[c[:column]] = res[c[:column]]}
        final
      end


      def get_hash(campus_ids, staff_id = nil)
        [campus_ids.nil? ? nil : campus_ids.hash, staff_id].compact.join("_")
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

      module YearClassMethods

        # This method will return the year id associated with a given description
        def find_year_id(description)
          find(:first, :conditions => {_(:description) => description}).id
        end

        # This method will return the description associated with a given year id
        def find_year_description(id)
          find(:first, :conditions => {_(:id) => id}).description
        end

        # This method will return an array of all the years up to and including the current year
        def find_years(current_id)
          find(:all, :conditions => ["#{_(:id)} <= ?",current_id]).collect{ |y| [y.description] }
        end

        # return the current year
        def current
          ::Month.find(:first, :conditions => {:month_calendaryear => Time.now.year, :month_number => Time.now.month}).year
        end
      end

    end
  end
end
