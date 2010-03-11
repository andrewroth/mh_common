module Legacy
  module Hrdb
    module Emerg

      def self.included(base)
        base.class_eval do
          belongs_to :person
        end
      end

    end
  end
end
