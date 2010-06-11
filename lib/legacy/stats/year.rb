module Legacy
  module Stats
    module Year

      def self.included(base)
        base.class_eval do
          has_many :months, :class_name => 'Month', :foreign_key => _(:year_id, :month)
          has_many :semesters, :class_name => 'Semester', :foreign_key => _(:year_id, :semester)
        end

        base.extend YearClassMethods
      end

      def start_date
        months.first.start_date
      end
      
      def end_date
        months.last.end_date
      end

      def evaluate_stat(campus_ids, stat_hash, staff_id = nil)
        total = 0
        if stat_hash[:column_type] == :database_column
          if stat_hash[:collected] == :weekly
            total = find_weekly_stats_campuses(campus_ids, stat_hash[:column], staff_id)
          else
            semesters.each { | semester | total += semester.evaluate_stat(campus_ids, stat_hash, staff_id) }         
          end
        end
        total
      end

      def get_hash(campus_ids, staff_id = nil)
        [campus_ids.nil? ? nil : campus_ids.hash, staff_id].compact.join("_")
      end
      
      def find_weekly_stats_campuses(campus_ids, stat, staff_id = nil)
        @weekly_sums ||= {}
        
        @weekly_sums[get_hash(campus_ids, staff_id)] ||= ::WeeklyReport.get_weekly_stats_sums_over_period(self, campus_ids, staff_id)
        result = @weekly_sums[get_hash(campus_ids, staff_id)][stat]
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
      end

    end
  end
end
