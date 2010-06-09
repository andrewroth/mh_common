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

      def evaluate_stat(campus_ids, stat_hash, staff_id = nil)
        #debugger if stat_hash[:column] == :weeklyReport_1on1HsPres
        total = 0
        semesters.each { | semester | total += semester.evaluate_stat(campus_ids, stat_hash, staff_id) }
        total
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
