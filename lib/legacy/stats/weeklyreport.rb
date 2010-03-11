module Legacy
  module Stats
    module Weeklyreport

      def self.included(base)
        base.class_eval do
          set_primary_key  _(:id)
          load_mappings
          belongs_to :week, :class_name => 'Week'
          belongs_to :campus, :class_name => 'Campus'
        end
      end


      module StatsClassMethods
        # This method will return all the given stat total during a given month on a given campus
        def find_stats_campus(month_id, campus_id, stat)
          result = find(:all, :joins => :week, :conditions => ["#{_(:campus_id)} = ? AND #{_(:month_id, :week)} = ?",campus_id,month_id] )
          total = result.sum(&stat) # sum the specific stat
          total
        end

        # This method will return the staff id(s) that have submitted stats during the given semester
        def find_staff(semester_id, campus_id, staff_id = nil)
          conditions = "#{__(:semester_id, :week)} = #{semester_id} AND #{_(:campus_id)} = #{campus_id}"
          conditions += " AND #{:staff_id} = #{staff_id}" if staff_id
          find(:all, :joins => :week, :select => 'DISTINCT staff_id', :conditions => conditions)
        end

        # This method is used to check whether a staff has submitted stats for a specific week
        def check_submitted(week_id, staff_id, campus_id)
          find(:first, :conditions => {_(:week_id) => week_id, _(:staff_id) => staff_id, _(:campus_id) => campus_id})
        end

        # This method is used to insert a new weekly stats report
        def submit_stats(week_id, campus_id, staff_id, sp_conv, sp_conv_std, gos_pres, gos_pres_std, hs_pres)
          report = self.check_submitted(week_id, staff_id, campus_id)
          unless report
            create(_(:week_id) => week_id, _(:campus_id) => campus_id, _(:staff_id) => staff_id, _(:spiritual_conversations) => sp_conv, _(:spiritual_conversations_student) => sp_conv_std, _(:gospel_presentations) => gos_pres, _(:gospel_presentations_student) => gos_pres_std, _(:holyspirit_presentations) => hs_pres )
          else
            report.spiritual_conversations = sp_conv
            report.spiritual_conversations_student = sp_conv_std
            report.gospel_presentations = gos_pres
            report.gospel_presentations_student = gos_pres_std
            report.holyspirit_presentations = hs_pres
            report.save!
          end
        end
      end
      
    end
  end
end

  
