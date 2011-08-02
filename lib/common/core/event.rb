module Common
  module Core
    module Event
      def self.included(base)
        base.class_eval do

          has_many :campuses, :through => :event_campuses, :order => __(:name, :campus)
          has_many :event_campuses, :include => :campus
          has_many :event_attendees
          belongs_to :event_group
          
        end
      end

    end
  end
end
