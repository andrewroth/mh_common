module Common
  module Core
    module EventGroup
      def self.included(base)
        base.class_eval do

          has_many :events
          
        end
      end

    end
  end
end
