module Common
  module Core
    module Ca
      module Country

        def self.included(base)
          base.class_eval do
            set_primary_key "country_id"
            has_many :states, :foreign_key => :country_id
            has_many :regions, :foreign_key => :country_id
            has_many :people,    :foreign_key => _(:person_id, :person)

            validates_no_association_data :states, :regions, :people
          end
        end



        def country() country_desc end
        def is_closed()
          nil
        end

      end
    end
  end
end
