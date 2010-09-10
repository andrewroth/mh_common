module Common
  module Core
    module Ca
      module Campus

        def self.included(base)
          base.class_eval do
            belongs_to :region, :foreign_key => :region_id
            belongs_to :state, :foreign_key => _(:state_id)
            has_many :assignments, :foreign_key => _(:campus_id, :assignment)

            validates_no_association_data :people, :campus_involvements, :groups, :ministry_campuses, :ministries, :dorms

            def type=(val) '' end
            def country=(val) '' end
            def enrollment() '' end
          end

          base.extend CampusClassMethods
        end


        def matches_eventbrite_campus(eb_campus_string)
          match = false
          
          desc = eb_campus_string.slice(0, eb_campus_string.rindex("(")-1)
          short_desc = eb_campus_string.slice(eb_campus_string.rindex("(")+1, eb_campus_string.rindex(")")-eb_campus_string.rindex("(")-1)

          match = true if (desc == self.desc || short_desc == self.short_desc)
          
          match
        end


        module CampusClassMethods
          def find_campus_from_eventbrite(eb_campus_string)
            # eb_campus_string should be in format "campus.desc (campus.short_desc)"
            desc = eb_campus_string.slice(0, eb_campus_string.rindex("(")-1)
            short_desc = eb_campus_string.slice(eb_campus_string.rindex("(")+1, eb_campus_string.rindex(")")-eb_campus_string.rindex("(")-1)

            ::Campus.first(:conditions => ["#{::Campus.table_name}.#{_(:campus_desc, :campus)} = \"#{desc}\" OR #{::Campus.table_name}.#{_(:short_desc, :campus)} = \"#{short_desc}\""])
          end
        end

      end
    end
  end
end
