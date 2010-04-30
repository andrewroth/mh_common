class Emerg
  BLOOD_TYPES = %w(A B AB O Unknown)
  BLOOD_TYPE_RH = [ "Positive", "Negative", "Unknown" ]
end

module Common
  module Core
    module Emerg
      def self.included(base)
        base.class_eval do
          belongs_to :person
        end
      end

      def contact_name
      end
    end
  end
end
