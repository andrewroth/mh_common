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
        end

      end
    end
  end
end
