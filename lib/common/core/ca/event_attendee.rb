module Common
  module Core
    module Ca
      module EventAttendee
        def self.included(base)
          base.class_eval do
            base.extend EventAttendeeClassMethods          
          end
        end


        module EventAttendeeClassMethods
          def update_or_create_from_eventbrite(attendee)
            return nil unless attendee && attendee.id
            
            event_attendee = ::EventAttendee.first(:conditions => {:ticket_id => attendee.id})
            
            event_attendee = ::EventAttendee.new({:ticket_id => attendee.id}) unless event_attendee.present?
            
            event = ::Event.first(:conditions => {:registrar_event_id => attendee.event_id})
            event_attendee.event_id = event.id if event
            
            event_attendee.email = attendee.email
            event_attendee.first_name = attendee.first_name
            event_attendee.last_name = attendee.last_name
            event_attendee.gender = attendee.gender
            event_attendee.campus = attendee.answer_to_question(eventbrite[:campus_question])
            event_attendee.year_in_school = attendee.answer_to_question(eventbrite[:year_question])
            event_attendee.home_phone = attendee.home_phone
            event_attendee.work_phone = attendee.work_phone
            event_attendee.cell_phone = attendee.cell_phone
            event_attendee.ticket_updated_at = attendee.modified
            
            event_attendee.save!
            
            # try to match this event_attendee to a person if there's no match yet
            unless ::PersonEventAttendee.first(:conditions => {:event_attendee_id => event_attendee.id}).present?
              person = ::Person.find_and_associate_person_to_event_attendee(event_attendee)
              
              # try to update their attributes based on what they entered into eventbrite
              person.update_from_latest_event_attendee if person
            end
          end
        end

      end
    end
  end
end
