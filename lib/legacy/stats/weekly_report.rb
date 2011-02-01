module Legacy
  module Stats
    module WeeklyReport

      def self.included(base)
        unloadable

        base.class_eval do
          set_primary_key  _(:id)
          load_mappings
          belongs_to :week, :class_name => 'Week'
          belongs_to :campus, :class_name => 'Campus'
          belongs_to :staff, :class_name => 'CimHrdbStaff'
          has_one :person, :through => :staff, :class_name => 'Person'

          validates_presence_of _(:week_id), 
                                _(:campus_id), 
                                _(:spiritual_conversations), 
                                _(:spiritual_conversations_student), 
                                _(:gospel_presentations), 
                                _(:gospel_presentations_student), 
                                _(:holyspirit_presentations), 
                                _(:weeklyReport_p2c_numCommitFilledHS), 
                                :message => "can't be blank, enter 0 if nothing happened during this period."
          validates_numericality_of _(:week_id), 
                                    _(:campus_id), 
                                    _(:spiritual_conversations), 
                                    _(:spiritual_conversations_student), 
                                    _(:gospel_presentations), 
                                    _(:gospel_presentations_student), 
                                    _(:holyspirit_presentations), 
                                    _(:weeklyReport_p2c_numCommitFilledHS), 
                                    :message => 'should be a number'
        end

        base.extend StatsClassMethods
      end


      module StatsClassMethods

        def get_start_week_id(period)
          start_week_id = 0
          if period.is_a?(Week)
            start_week_id = period.id
          elsif period.is_a?(Year)
            start_week_id = period.semesters.first.weeks.first.id
          else
            start_week_id = period.weeks.first.id
          end
          start_week_id
        end

        def get_end_week_id(period)
          end_week_id = 0
          if period.is_a?(Week)
            end_week_id = period.id
          elsif period.is_a?(Year)
            end_week_id = period.semesters.last.weeks.last.id
          else
            end_week_id = period.weeks.last.id           
          end
          end_week_id    
        end

        def get_weekly_stats_sums_over_period(period, campus_ids, staff_id = nil)
          start_week_id = get_start_week_id(period)
          end_week_id = get_end_week_id(period)

          select = stats_reports.collect{|k, v| stats_reports[k].collect{|k, c| (c[:column_type] == :database_column && c[:collected] == :weekly && c[:grouping_method] == :sum) ? c[:column] : nil}.compact }.flatten.uniq.compact.collect{|c| "sum(#{c}) as #{c}"}.join(', ')
          conditions = []
          conditions += ["#{_(:campus_id, :weekly_reports)} IN (#{campus_ids.join(',')})"] unless campus_ids.nil?
          conditions += ["#{_(:staff_id, :weekly_reports)} = (#{staff_id})"] unless staff_id.nil?
          conditions += ["#{_(:week_id, :weekly_reports)} >= (#{start_week_id})", 
                         "#{_(:week_id, :weekly_reports)} <= (#{end_week_id})"]
          find(:all, :select => select, :conditions => [conditions.join(' AND ')]).first
        end

        def get_last_non_zero_weekly_stats_over_period(period, stat, campus_ids, staff_id = nil)
          start_week_id = get_start_week_id(period)
          end_week_id = get_end_week_id(period)
          
          result = 0
          
          unless campus_ids.nil?
            campus_ids.each do |c_id|
              conditions = []
              conditions += ["#{_(:campus_id, :weekly_reports)} = #{c_id}"]
              conditions += ["#{_(:staff_id, :weekly_reports)} = (#{staff_id})"] unless staff_id.nil?
              conditions += ["#{_(:week_id, :weekly_reports)} >= (#{start_week_id})", 
                             "#{_(:week_id, :weekly_reports)} <= (#{end_week_id})"]
              conditions += ["#{stat} <> 0"]
              wr = find(:last, :select => stat, :conditions => [conditions.join(' AND ')], :order => ["#{_(:week_id, :weekly_reports)}"])
              result += wr[stat] unless wr.nil?
            end
          else
              conditions += ["#{_(:staff_id, :weekly_reports)} = (#{staff_id})"] unless staff_id.nil?
              conditions += ["#{_(:week_id, :weekly_reports)} >= (#{start_week_id})", 
                             "#{_(:week_id, :weekly_reports)} <= (#{end_week_id})"]
              conditions += ["#{stat} <> 0"]
              wr = find(:last, :select => stat, :conditions => [conditions.join(' AND ')], :order => ["#{_(:week_id, :weekly_reports)}"])
              result += wr[stat] unless wr.nil?
          end
          result
        end


        # returns a hash of all five stats based on a range of week end dates at a campus
        def find_all_stats_by_date_range_and_campus(first_week_end_date, last_week_end_date, campus_id)
          reports = find(:all, :joins => :week, :conditions => ["#{_(:week_endDate, :week)} >= ? AND #{_(:week_endDate, :week)} <= ? AND #{_(:campus_id, :weekly_report)} = ?", first_week_end_date, last_week_end_date, campus_id])

          stats = {gos_pres => reports.sum(&gos_pres),
                   gos_pres_std => reports.sum(&gos_pres_std),
                   sp_conv => reports.sum(&sp_conv),
                   sp_conv_std => reports.sum(&sp_conv_std),
                   hs_pres => reports.sum(&hs_pres)}
        end

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

  
