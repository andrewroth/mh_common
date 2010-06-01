module Legacy
  module Stats
    module Week

      unloadable

      def self.included(base)
        base.class_eval do
          has_many :weekly_reports, :class_name => 'WeeklyReport', :foreign_key => _(:week_id, :weekly_report)
          belongs_to :campus, :class_name => 'Campus'
          belongs_to :month, :class_name => 'Month'
          belongs_to :semester, :class_name => 'Semester'
        end

        base.extend StatsClassMethods
      end

      # This method will return the given stat total associated with the given campus ids
      def sum_stat_for_campuses(campus_ids, stat)
        weekly_reports.sum(_(stat, :weekly_reports), :conditions => ["#{_(:campus_id, :weekly_reports)} IN (?)", campus_ids])
      end

      def evaluate_stat(campus_ids, stat_hash)
        evaluation = 0
        if stat_hash[:column_type] == :database_column
          if stat_hash[:collected] == :weekly
            evaluation = sum_stat_for_campuses(campus_ids, stat_hash[:column])
          elsif stat_hash[:collected] == :prc
            evaluation = find_prcs_campuses(campus_ids)
          end
        end
        evaluation
      end

      def start_date
        end_date - 7
      end
      
      def find_prcs_campuses(campus_ids)
        semester.prcs.count(:all, :conditions => ["#{_(:campus_id, :prc)} IN (?) AND #{_(:date, :prc)} > '#{start_date.strftime('%Y-%m-%d')}' AND #{_(:date, :prc)} <= '#{end_date.strftime('%Y-%m-%d')}'", campus_ids])
      end

      module StatsClassMethods

        # This method will return the given stat total associated with a given staff id
        def find_stats_staff(week_id,staff_id,stat,campus_id)
          week = find(:first, :conditions => {_(:id) => week_id})
          result = week.weekly_reports.find(:all, :conditions => [ "#{_(:staff_id)} = ? AND #{_(:campus_id)} = ?", staff_id, campus_id ])
          result.sum(&stat) # sum the specific stat
        end

        # This method will return the given stat total associated with a given week id in a given ministry
        def find_ministry_stats_week(week_id,ministry_id,stat)
          week = find(:first, :conditions => {_(:id) => week_id})
          campus_ids = Ministry.find(ministry_id).unique_campuses.collect {|c| c.id}

          result = week.weekly_reports.find(:all, :joins => :campus, :conditions => [ "#{__(:campus_id, :campus)} IN (?)", campus_ids ])

          result.sum(&stat) # sum the specific stat
        end

        # This method will return the given stat total associated with a given week id in a given region
        def find_stats_week(week_id,region_id,stat)
          week = find(:first, :conditions => {_(:id) => week_id})
          # national team stats are not included, so if the region_id is the national_region then it means total all other regions
          if region_id == national_region
            result = week.weekly_reports.find(:all, :joins => :campus, :conditions => [ "#{__(:region_id, :campus)} != ?", region_id ])
          else # else just find the stats associated with the given region
            result = week.weekly_reports.find(:all, :joins => :campus, :conditions => [ "#{__(:region_id, :campus)} = ?", region_id ])
          end
          result.sum(&stat) # sum the specific stat
        end

        # This method will return the given stat total associated with a given month id in a given ministry
        def find_ministry_stats_month(month_id,ministry_id,stat)
          weeks = find(:all, :conditions => {_(:month_id) => month_id})
          campus_ids = Ministry.find(ministry_id).unique_campuses.collect {|c| c.id}

          total = 0

          weeks.each do |week| # for each week find the stat and add it to the total
            result = week.weekly_reports.find(:all, :joins => :campus, :conditions => [ "#{__(:id, :campus)} IN (?)", campus_ids ])
            total += result.sum(&stat) # sum the specific stat
          end
          
          total
        end

        # This method will return the given stat total associated with a given month id in a given region
        def find_stats_month(month_id,region_id,stat)
          weeks = find(:all, :conditions => {_(:month_id) => month_id})
          total = 0
          # national team stats are not included, so if the region_id is the national_region then it means total all other regions
          if region_id == national_region
            weeks.each do |week| # for each week find the stat and add it to the total
              result = week.weekly_reports.find(:all, :joins => :campus, :conditions => [ "#{__(:region_id, :campus)} != ?", region_id ])
              total += result.sum(&stat) # sum the specific stat
            end
          else # else just find the stats associated with the given region
            weeks.each do |week| # for each week find the stat and add it to the total
              result = week.weekly_reports.find(:all, :joins => :campus, :conditions => [ "#{__(:region_id, :campus)} = ?", region_id ])
              total += result.sum(&stat) # sum the specific stat
            end
          end
          total
        end

        # This method will return the given stat total associated with a given semester id in a given region
        def find_stats_semester(semester_id,region_id,stat)
          weeks = find(:all, :conditions => {_(:semester_id) => semester_id})
          total = 0
          # national team stats are not included, so if the region_id is the national_region then it means total all other regions
          if region_id == national_region
            weeks.each do |week| # for each week find the stat and add it to the total
              result = week.weekly_reports.find(:all, :joins => :campus, :conditions => [ "#{__(:region_id, :campus)} != ?", region_id ])
              total += result.sum(&stat) # sum the specific stat
            end
          else # else just find the stats associated with the given region
            weeks.each do |week| # for each week find the stat and add it to the total
              result = week.weekly_reports.find(:all, :joins => :campus, :conditions => [ "#{__(:region_id, :campus)} = ?", region_id ])
              total += result.sum(&stat) # sum the specific stat
            end
          end
          total
        end

        # This method will return the given stat total associated with a given semester and a given ministry
        def find_stats_semester_ministry(semester_id,ministry_id,stat)
          weeks = find(:all, :conditions => {_(:semester_id) => semester_id})
          campus_ids = Ministry.find(ministry_id).unique_campuses.collect {|c| c.id}
          total = 0
          weeks.each do |week| # for each week find the stat and add it to the total
            result = week.weekly_reports.find(:all, :conditions => ["#{_(:campus_id)} IN (?)", campus_ids])
            total += result.sum(&stat) # sum the specific stat
          end
          total
        end

        def find_stats_semester_campuses(semester_id,campuses,stat)
          weeks = find(:all, :conditions => {_(:semester_id) => semester_id})
          campus_ids = campuses.collect {|c| c.id}
          total = 0
          weeks.each do |week| # for each week find the stat and add it to the total
            result = week.weekly_reports.find(:all, :conditions => ["#{_(:campus_id)} IN (?)", campus_ids])
            total += result.sum(&stat) # sum the specific stat
          end
          total
        end

        # This method will return the given stat total associated with a given semester and a given campus
        def find_stats_semester_campus(semester_id,campus_id,stat)
          weeks = find(:all, :conditions => {_(:semester_id) => semester_id})
          total = 0
          weeks.each do |week| # for each week find the stat and add it to the total
            result = week.weekly_reports.find(:all, :conditions => {_(:campus_id) => campus_id})
            total += result.sum(&stat) # sum the specific stat
          end
          total
        end

        # This method will return the week id associated with a given end date
        def find_week_id(end_date)
          week = find(:first, :select => _(:id), :conditions => {_(:end_date) => end_date})
          week ? week.id : nil
        end

        # This method will return the start date associated with a given week id
        def find_start_date(week_id)
          week = find(:first, :select => :week_endDate, :conditions => {_(:id) => (week_id-1)} )
          week ? week.end_date : nil
        end

        # This method will return the end date associated with a given week id
        def find_end_date(week_id)
          week = find(:first, :select => :week_endDate, :conditions => {_(:id) => week_id} )
          week ? week.end_date : nil
        end

        # This method will return all the weeks associated with a given month id
        def find_weeks_in_month(month_id)
          find(:all, :select => _(:id), :conditions => { _(:month_id) => month_id }, :order => _(:id))
        end

        # This method will return all the weeks associated with a given semester id
        def find_weeks_in_semester(semester_id)
          find(:all, :conditions => { _(:semester_id) => semester_id }, :order => _(:id))
        end

        # This method will return an array of all the week end dates in the table
        def find_weeks()
          find(:all, :select => _(:end_date), :order => _(:end_date)).collect{ |w| [w.end_date]}
        end

        # This method will return the semester id associated with a given week id
        def find_semester_id(id)
          find(:first, :conditions => {_(:id) => id})["#{_(:semester_id)}"]
        end
      end
    end
  end
end
