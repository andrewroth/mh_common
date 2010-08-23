module Common
  module Core
    module Year
      def self.included(base)
        base.class_eval do
          has_many :semesters
        end
      end

      # oddly, calling just desc in a rake task gives an error about accessing
      # a private method, so use this instead
      def description
        self[:desc]
      end
    end
  end
end
