module Common
  module Core
    module Year
      def self.included(base)
        base.class_eval do
          has_many :semesters
          has_many :months_by_literal_year, :primary_key => :year_number, :foreign_key => :month_literalyear, 
            :class_name => "Month"

          default_scope :order => 'year_number ASC'
        end
      end

      # oddly, calling just desc in a rake task gives an error about accessing
      # a private method, so use this instead
      def description
        self[:desc]
      end

      def current
        self.find_by_year_number(Date.today.year)
      end
    end
  end
end
