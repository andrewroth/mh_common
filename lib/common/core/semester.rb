module Common
  module Core
    module Semester
      def self.included(base)
        base.class_eval do
          belongs_to :semester # this is confusing
          has_one :month

          def next_semester
            ::Semester.first(:order => "#{::Semester._(:start_date)} ASC", :conditions => [ "#{::Semester._(:start_date)} > ?", self.start_date ])
          end

          def previous_semester
            ::Semester.first(:order => "#{::Semester._(:start_date)} DESC", :conditions => [ "#{::Semester._(:start_date)} < ?", self.start_date ])
          end

          def self.current
            # find the latest semester with the latest start_date still before the current date
            # any semester with a start date later than today is surely not the current one
            sd_column = ::Semester._(:start_date)
            semesters = ::Semester.all(:order => "#{sd_column} ASC", :conditions => [ "#{sd_column} <= ?", Date.today ] ) 
            semesters.inject(nil) do |best, curr|
              if best.nil?
                curr
              elsif curr.start_date > best.start_date     
                # curr is newer
                curr
              else
                best
              end
            end
          end

          def self.create_default_semesters(num_years_to_add, also_add_weeks_and_months = false)
            num_years_to_add.times do

              # add year first
              last_year = ::Year.all.last
              new_year = ::Year.new
              if last_year
                last_year_year = last_year.description[-4..-1].to_i
              else
                last_year_year = Date.today.year - 1 # use last year to be safe; in this case,
                   # the calling method should put num_years_to_add to at least 2.  This is
                   # the initialization case anyways so it should only happen once.
              end
              new_year.desc = "#{last_year_year} - #{last_year_year+1}"
              puts "Adding year #{new_year.desc}" unless Rails.env.test?
              new_year.save

                # for each year, if there are not 3 semesters, add them
              ::Year.all.each do |year|
                unless year.semesters.size == 3

                  # create fall semester
                  unless year.semesters.all(:conditions => ["#{::Semester.__(:desc)} = 'Fall #{year.desc[0..3]}'"]).any?

                    new_semester = year.semesters.build(:desc => "Fall #{year.desc[0..3]}",
                                                        :start_date => "#{year.desc[0..3]}-09-01")
                    puts "Adding semester #{new_semester.desc}" unless Rails.env.test?
                    new_semester.save
                  end

                  # create winter semester
                  unless year.semesters.all(:conditions => ["#{::Semester.__(:desc)} = 'Winter #{year.desc[-4..-1]}'"]).any?

                    new_semester = year.semesters.build(:desc => "Winter #{year.desc[-4..-1]}",
                                                        :start_date => "#{year.desc[-4..-1]}-01-01")
                    puts "Adding semester #{new_semester.desc}" unless Rails.env.test?
                    new_semester.save
                  end

                  # create summer semester
                  unless year.semesters.all(:conditions => ["#{::Semester.__(:desc)} = 'Summer #{year.desc[-4..-1]}'"]).any?

                    new_semester = year.semesters.build(:desc => "Summer #{year.desc[-4..-1]}",
                                                        :start_date => "#{year.desc[-4..-1]}-05-01")
                    puts "Adding semester #{new_semester.desc}" unless Rails.env.test?
                    new_semester.save
                  end
                end # year == 3
              end # years loop


              if also_add_weeks_and_months
                # for each year, if there are not 12 months, add them
                ::Year.all.each do |year|
                  unless year.months.size == 12

                    if year.months.any?
                      last_month_number = year.months.last.month_number
                      month_counter = last_month_number == 12 ? 1 : last_month_number + 1
                    else
                      month_counter = 9 # month 9, September, is the first month of a year
                    end

                    while year.months.size < 12 do
                      new_month = year.months.build(:month_number => month_counter)

                      new_month.calendar_year = month_counter > 8 ? year.description[0..3] : year.description[-4..-1]

                      new_month.description = "#{Date::MONTHNAMES[month_counter]} #{new_month.calendar_year}"

                      new_month.semester_id = ::Semester.find_semester_from_date("#{new_month.calendar_year}-#{month_counter}-1").id

                      puts "Adding month #{new_month.description}" unless Rails.env.test?
                      new_month.save

                      month_counter = month_counter == 12 ? 1 : month_counter + 1
                    end

                  end
                end


                # go to last week and, stopping after the last month, add enough weeks

                last_week = ::Week.all(:order => "#{::Week._(:end_date)} asc").last
                week_counter_date = Date.parse(last_week.end_date.to_s)
                raise "The last week in your database has an unexpected date (it is not a Saturday)" if week_counter_date.wday != 6 && !Rails.env.test?
                week_counter_date += 7

                last_month = ::Month.all(:order => "#{::Month._(:calendar_year)} asc, #{::Month._(:month_number)} asc").last
                last_month_date = Date.parse("#{last_month.description[-4..-1]}-#{last_month.month_number}-4") # if day is <= 3 it belongs to previous month
                last_month_date = last_month_date >> 1 # get date of first day of next month

                while week_counter_date.year < last_month_date.year || (week_counter_date.year == last_month_date.year && week_counter_date.month < last_month_date.month) do
                  new_week = ::Week.new
                  new_week.end_date = week_counter_date

                  # set semester_id
                  new_week.semester_id = ::Semester.find_semester_from_date(new_week.end_date, true).id

                  # set month_id
                  new_week.month_id = ::Month.find_month_from_date(new_week.end_date, true).id

                  puts "Adding week #{new_week.end_date}" unless Rails.env.test?
                  new_week.save

                  week_counter_date += 7
                end
              end # if also_add_weeks_and_months

            end # num years to add
          end
        end
      end
    end
  end
end
