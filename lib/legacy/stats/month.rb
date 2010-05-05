module Legacy
  module Stats
    module Month

      def self.included(base)
        base.class_eval do
          belongs_to :year, :class_name => 'Year'
          belongs_to :semester, :class_name => 'Semester'
          has_many :weeks, :class_name => 'Week', :foreign_key => _(:month_id, :week)
        end

        base.extend StatsClassMethods
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
