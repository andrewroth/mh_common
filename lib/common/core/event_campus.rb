module Common
  module Core
    module EventCampus
      def self.included(base)
        base.class_eval do

          belongs_to :campus
          belongs_to :event
          
        end
      end

    end
  end
end
