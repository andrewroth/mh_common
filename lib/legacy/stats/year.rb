module Legacy
  module Stats
    module Year

      def self.included(base)
        base.class_eval do

        end
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
