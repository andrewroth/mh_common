module Legacy
  module Hrdb
    module CimHrdbPersonYear

      def self.included(base)
        base.class_eval do
          belongs_to :person
          belongs_to :school_year, :foreign_key => 'year_id'
        end
      end

    end
  end
end

