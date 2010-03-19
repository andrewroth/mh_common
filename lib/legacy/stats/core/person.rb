module Legacy
  module Stats
    module Core
      module Person

        def self.included(base)
          base.class_eval do
          end

          base.extend PersonClassMethods
        end


        module PersonClassMethods
          # This method will return the person associated with a given id
          def find_person(person_id)
            find(:first, :conditions => {_(:id) => person_id})
          end
        end

      end
    end
  end
end
