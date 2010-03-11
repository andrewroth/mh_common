module Legacy
  module Hrdb
    module Region

      def self.included(base)
        base.class_eval do
          has_many :campuses
          belongs_to :country, :foreign_key => :country_id

          validates_no_association_data :campuses
        end
      end

      module RegionClassMethods
        # This method will return an array of all regions associated with a given country
        def find_regions(country_id)
          find(:all, :conditions => ["#{_(:country_id)} <= ?",country_id]).collect{ |s| [s.desc]}
        end

        # This method will return the region id associated with a given description
        def find_region_id(description)
          find(:first, :conditions => {_(:desc) => description}).id
        end
      end

    end
  end
end
