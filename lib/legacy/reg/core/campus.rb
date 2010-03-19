module Legacy
  module Reg
    module Core
      module Campus

        def self.included(base)
          base.class_eval do
          end
        end


        def all_assignments()
          Assignment.all(:joins => :person,
                         :order => __(:first_name, :person) + " ASC, " + __(:last_name, :person) + " ASC",
                         :conditions => ["#{__(:campus_id, :assignment)} = ?", self.id])
        end


      end
    end
  end
end
