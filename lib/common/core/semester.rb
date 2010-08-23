module Common
  module Core
    module Semester
      def self.included(base)
        base.class_eval do
          belongs_to :semester
        end
      end
    end
  end
end
