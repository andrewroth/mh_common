module Legacy
  module Stats
    module AnnualReport

      def self.included(base)
        unloadable

        base.class_eval do
          set_primary_key  _(:id)
          load_mappings
          belongs_to :year, :class_name => 'Year'
          belongs_to :campus, :class_name => 'Campus'

          validates_presence_of :campus_id,
                                :year_id
                                
          validates_numericality_of :campus_id,
                                    :year_id
        end

        base.extend StatsClassMethods
      end

      module StatsClassMethods

      end

    end
  end
end
