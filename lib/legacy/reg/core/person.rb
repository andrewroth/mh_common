module Legacy
  module Reg
    module Core
      module Person

        def self.included(base)
          base.class_eval do

            has_many :registrations, :foreign_key => _(:person_id, :registration)
            has_many :events, :through => :registrations
            belongs_to :local_province_assoc, :class_name => "State", :foreign_key => :person_local_province_id

            # handle states with id of 0
            def state(*args)
              self.province_id == 0 ? ::State.new : self.state_assoc(*args)
            end

            # handle local_provinces with id of 0
            def local_province(*args)
              self.person_local_province_id == 0 ? ::State.new : self.local_province_assoc(*args)
            end
          end

        end

        
        def get_best_assigned_campus()

          # people can have multiple assignments to campuses and there is no good way to pick just one
          # do our best to pick the most appropriate campus assignment by picking the one with
          # the highest id where that person has student status
          # if the person has no assignments with student status just pick the highest id

          assignment = self.assignments.first(:include => :assignmentstatus,
                                              :conditions => ["#{__(:description, :assignmentstatus)} = ?", Assignmentstatus::CURRENT_STUDENT],
                                              :order => "#{__(:id, :assignment)} DESC")

          if !assignment then
            assignment = self.assignments.first(:order => "#{__(:id, :assignment)} DESC")
          end

          assignment.campus
        end


      end
    end
  end
end
