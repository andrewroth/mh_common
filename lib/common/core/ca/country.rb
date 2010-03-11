module Common
  module Core
    module Ca
      module Country

        def self.included(base)
          base.class_eval do
            set_primary_key "country_id"
            has_many :states, :foreign_key => :country_id
            has_many :regions, :foreign_key => :country_id
            has_many :people

            validates_no_association_data :states, :regions, :people
          end

          base.extend CountryClassMethods
        end

        def country() country_desc end
        def is_closed()
          nil
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
