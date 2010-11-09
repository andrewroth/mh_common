module Legacy
  module Stats
    module AnnualGoalsReport

      def self.included(base)
        unloadable

        base.class_eval do
          set_primary_key  _(:id)
          load_mappings
          belongs_to :year, :class_name => 'Year'
          belongs_to :campus, :class_name => 'Campus'

          validates_presence_of :campus_id,
                                :year_id,
                                :annualGoalsReport_studInMin,
                                :annualGoalsReport_sptMulti,
                                :annualGoalsReport_firstYears,
                                :annualGoalsReport_summitWent,
                                :annualGoalsReport_wcWent,
                                :annualGoalsReport_projWent,
                                :annualGoalsReport_spConvTotal,
                                :annualGoalsReport_gosPresTotal,
                                :annualGoalsReport_hsPresTotal,
                                :annualGoalsReport_prcTotal,
                                :annualGoalsReport_integBelievers,
                                :annualGoalsReport_lrgEventAttend,
                                :message => "can't be blank, enter 0 if nothing happened during this period."
                                
          validates_numericality_of :campus_id,
                                    :year_id,
                                    :annualGoalsReport_studInMin,
                                    :annualGoalsReport_sptMulti,
                                    :annualGoalsReport_firstYears,
                                    :annualGoalsReport_summitWent,
                                    :annualGoalsReport_wcWent,
                                    :annualGoalsReport_projWent,
                                    :annualGoalsReport_spConvTotal,
                                    :annualGoalsReport_gosPresTotal,
                                    :annualGoalsReport_hsPresTotal,
                                    :annualGoalsReport_prcTotal,
                                    :annualGoalsReport_integBelievers,
                                    :annualGoalsReport_lrgEventAttend, 
                                    :message => 'should be a number'

        end

        base.extend StatsClassMethods
      end

      module StatsClassMethods

      end

    end
  end
end
