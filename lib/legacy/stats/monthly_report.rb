module Legacy
  module Stats
    module MonthlyReport

      def self.included(base)
        unloadable

        base.class_eval do
          set_primary_key  _(:id)
          load_mappings
          belongs_to :month, :class_name => 'Month'
          belongs_to :campus, :class_name => 'Campus'

        end

        base.extend StatsClassMethods
      end

      module StatsClassMethods

      end

    end
  end
end
