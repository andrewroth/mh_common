module Common
  module Core
    module PersonEventAttendee
      def self.included(base)
        base.class_eval do

          belongs_to :event_attendee
          belongs_to :person
          
        end
      end

    end
  end
end
