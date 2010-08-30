module Common
  module Core
    module Semester
      def self.included(base)
        base.class_eval do
          belongs_to :semester

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

          def self.create_default_semesters(num_years_to_add)
            num_years_to_add.times do

              # add year first
              last_year = ::Year.last
              new_year = ::Year.new
              if last_year
                last_year_year = last_year.description[-4..-1].to_i
              else
                last_year_year = Date.today.year - 1 # use last year to be safe; in this case,
                   # the calling method should put num_years_to_add to at least 2.  This is
                   # the initialization case anyways so it should only happen once.
              end
              new_year.desc = "#{last_year_year} - #{last_year_year+1}"
              puts "Adding year #{new_year.desc}"
              new_year.save

                # for each year, if there are not 3 semesters, add them
              ::Year.all.each do |year|
                unless year.semesters.size == 3

                  # create fall semester
                  unless year.semesters.all(:conditions => {:desc => "Fall #{year.desc[0..3]}"}).any?

                    new_semester = year.semesters.build(:desc => "Fall #{year.desc[0..3]}",
                                                        :start_date => "#{year.desc[0..3]}-09-01")
                    puts "Adding semester #{new_semester.desc}"
                    new_semester.save
                  end

                  # create winter semester
                  unless year.semesters.all(:conditions => {:desc => "Winter #{year.desc[-4..-1]}"}).any?

                    new_semester = year.semesters.build(:desc => "Winter #{year.desc[-4..-1]}",
                                                        :start_date => "#{year.desc[-4..-1]}-01-01")
                    puts "Adding semester #{new_semester.desc}"
                    new_semester.save
                  end

                  # create summer semester
                  unless year.semesters.all(:conditions => {:desc => "Summer #{year.desc[-4..-1]}"}).any?

                    new_semester = year.semesters.build(:desc => "Summer #{year.desc[-4..-1]}",
                                                        :start_date => "#{year.desc[-4..-1]}-05-01")
                    puts "Adding semester #{new_semester.desc}"
                    new_semester.save
                  end
                end # year == 3
              end # years loop
            end # num years to add
          end
        end
      end
    end
  end
end
