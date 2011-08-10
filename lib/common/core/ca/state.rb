module Common
  module Core
    module Ca
      module State

        def self.included(base)
          base.class_eval do
            has_many :people, :foreign_key => :province_id
            belongs_to :country, :foreign_key => _(:country_id)

            validates_no_association_data :campuses, :people

          end
          base.extend StateClassMethods
        end

        module StateClassMethods
          def US_STATES
            ::Country.find_by_country_shortDesc("USA").states(:order => "province_shortDesc").collect{ |s| [ s.province_shortDesc, s.province_desc ] }
          end
        end
      end
    end
  end
end
