module Common
  module Core
    module County
      def self.included(base)
        base.class_eval do
          load_mappings
        end
      end
    end
  end
end
