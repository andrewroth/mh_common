module Legacy
  module Stats
    module Core
      module Country

        def self.included(base)
          base.class_eval do
          end

          base.extend CountryClassMethods
        end

        module CountryClassMethods
          # This method will return the county id associated with a given description
          def find_country_id(description)
            find(:first, :conditions => ["#{_(:desc)} <= ?",description]).id
          end
        end

      end
    end
  end
end
