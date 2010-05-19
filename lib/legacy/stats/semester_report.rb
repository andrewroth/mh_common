module Legacy
  module Stats
    module SemesterReport

      def self.included(base)
        unloadable

        base.class_eval do
          set_primary_key  _(:id)
          load_mappings
          belongs_to :semester, :class_name => 'Semester'
          belongs_to :campus, :class_name => 'Campus'

          validates_presence_of _(:semester_id), 
                                _(:campus_id), 
                                _(:average_hours_prayer), 
                                _(:average_attendance_weekly_meetings), 
                                _(:number_challenged_staff), 
                                _(:number_challenged_internships), 
                                _(:number_frosh_involved), 
                                _(:number_staff_led_dg), 
                                _(:number_in_staff_led_dg), 
                                _(:number_student_led_dg), 
                                _(:number_in_student_led_dg), 
                                _(:number_sp_mult_in_staff_led_dg), 
                                _(:number_sp_mult_in_student_led_dg), 
                                _(:total_graduating_students_to_non_ministry), 
                                _(:total_graduating_students_to_full_time_c4c_staff), 
                                _(:total_graduating_students_to_full_time_p2c_non_c4c), 
                                _(:total_graduating_students_to_one_year_internship), 
                                _(:total_graduating_students_to_other_ministry)
          validates_numericality_of _(:semester_id), 
                                    _(:campus_id), 
                                    _(:average_hours_prayer), 
                                    _(:average_attendance_weekly_meetings), 
                                    _(:number_challenged_staff), 
                                    _(:number_challenged_internships), 
                                    _(:number_frosh_involved), 
                                    _(:number_staff_led_dg), 
                                    _(:number_in_staff_led_dg), 
                                    _(:number_student_led_dg), 
                                    _(:number_in_student_led_dg), 
                                    _(:number_sp_mult_in_staff_led_dg), 
                                    _(:number_sp_mult_in_student_led_dg), 
                                    _(:total_graduating_students_to_non_ministry), 
                                    _(:total_graduating_students_to_full_time_c4c_staff), 
                                    _(:total_graduating_students_to_full_time_p2c_non_c4c), 
                                    _(:total_graduating_students_to_one_year_internship), 
                                    _(:total_graduating_students_to_other_ministry)
        end

        base.extend StatsClassMethods
      end

      module StatsClassMethods

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

  
