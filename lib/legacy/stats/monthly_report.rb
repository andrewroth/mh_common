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

          validates_presence_of :campus_id,
                                :month_id,
                                :monthlyreport_avgPrayer,
                                :monthlyreport_numFrosh,
                                :monthlyreport_eventSpirConversations,
                                :monthlyreport_eventGospPres,
                                :monthlyreport_mediaSpirConversations,
                                :monthlyreport_mediaGospPres,
                                :monthlyreport_totalCoreStudents,
                                :monthlyreport_totalStudentInDG,
                                :monthlyreport_totalSpMult,
                                :montlyreport_p2c_numInEvangStudies,
                                :montlyreport_p2c_numTrainedToShareInP2c,
                                :montlyreport_p2c_numTrainedToShareOutP2c,
                                :montlyreport_p2c_numSharingInP2c,
                                :montlyreport_p2c_numSharingOutP2c,
                                :montlyreport_integratedNewBelievers,
                                :monthlyreport_event_exposures,
                                :monthlyreport_unrecorded_engagements,
                                :message => "can't be blank, enter 0 if nothing happened during this period."

          validates_numericality_of :campus_id,
                                :month_id,
                                :monthlyreport_avgPrayer,
                                :monthlyreport_numFrosh,
                                :monthlyreport_eventSpirConversations,
                                :monthlyreport_eventGospPres,
                                :monthlyreport_mediaSpirConversations,
                                :monthlyreport_mediaGospPres,
                                :monthlyreport_totalCoreStudents,
                                :monthlyreport_totalStudentInDG,
                                :monthlyreport_totalSpMult,
                                :montlyreport_p2c_numInEvangStudies,
                                :montlyreport_p2c_numTrainedToShareInP2c,
                                :montlyreport_p2c_numTrainedToShareOutP2c,
                                :montlyreport_p2c_numSharingInP2c,
                                :montlyreport_p2c_numSharingOutP2c,
                                :montlyreport_integratedNewBelievers,
                                :monthlyreport_event_exposures,
                                :monthlyreport_unrecorded_engagements,
                                :message => 'should be a number'
        end

        base.extend StatsClassMethods
      end

      module StatsClassMethods

      end

    end
  end
end
