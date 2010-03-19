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
        end

      end
    end
  end
end
