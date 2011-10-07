module Common
  module Core
    module Ca
      module Campus

        def self.included(base)
          base.class_eval do
            belongs_to :region, :foreign_key => :region_id
            belongs_to :state, :foreign_key => _(:state_id)
            has_many :assignments, :foreign_key => _(:campus_id, :assignment)

            validates_presence_of :desc, :short_desc, :province_id, :longitude, :latitude
            validates_no_association_data :people, :campus_involvements, :groups, :ministry_campuses, :ministries, :dorms

            def type=(val) '' end
            def country=(val) '' end
            def country() region.country end
            def enrollment() '' end
          end

          base.extend CampusClassMethods
        end


        def matches_eventbrite_campus(eb_campus_string)
          self == ::Campus.find_campus_from_eventbrite(eb_campus_string)
        end


        module CampusClassMethods
          def find_campus_from_eventbrite(eb_campus_string)
            return nil unless eb_campus_string
            unless eb_campus_string.include? "("
              desc = eb_campus_string
              short_desc = ""
            else
              desc = eb_campus_string.slice(0, eb_campus_string.rindex("(")-1)
              short_desc = eb_campus_string.slice(eb_campus_string.rindex("(")+1, eb_campus_string.rindex(")")-eb_campus_string.rindex("(")-1)
            end
            campus = ::Campus.first(:conditions => ["#{::Campus._(:campus_desc)} = ? or #{::Campus._(:short_desc)} = ?", desc, short_desc])
          end
          
          def find_nearest_to(lat, lng)
            ::Campus.find(:first,
                          :select => "*, ( 6371 * acos( cos( radians(#{lat}) ) * cos( radians( #{::Campus._(:latitude)} ) ) *
                                      cos( radians( #{::Campus._(:longitude)} ) - radians(#{lng}) ) + sin( radians(#{lat}) ) *
                                      sin( radians( #{::Campus._(:latitude)} ) ) ) ) AS distance",
                          :group => "#{::Campus._(:id)} HAVING distance IS NOT NULL",
                          :order => "distance ASC")
          end
        end

      end
    end
  end
end
