module Common
  module Core
    module InvolvementHistory
      def self.included(base)
        base.class_eval do
          belongs_to :person
          belongs_to :campus
          belongs_to :ministry_role
          belongs_to :school_year
          belongs_to :ministry
        end
      end
    end
  end
end
