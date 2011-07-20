module Common
  module Core
    module EventAttendee
      def self.included(base)
        base.class_eval do

          belongs_to :event
          
        end
      end

    end
  end
end
