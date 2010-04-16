module Common
  module Core
    module Staff
      def self.included(base)
        base.class_eval do
          unloadable
        end
      end
    end
  end
end
