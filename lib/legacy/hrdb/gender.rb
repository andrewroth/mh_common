module Legacy
  module Hrdb
    module Gender

      def self.included(base)
        base.class_eval do
          has_many :people
          validates_no_association_data :people
        end
      end

    end
  end
end
