module Common
  module Core
    module Ca
      module Event
        def self.included(base)
          base.class_eval do
            def eventbrite_id() self.registrar_event_id end
            
            base.extend EventClassMethods
          end
        end


        def all_attendees_from_campus(campus)
          attendees = []

          @eventbrite_user = EventBright.setup_from_initializer()

          eb_event = EventBright::Event.new(@eventbrite_user, {:id => self.eventbrite_id})

          eb_event.attendees.each do |attendee|
            if attendee.answers then
              answer = attendee.answer_to_question(eventbrite[:campus_question])

              if answer
                # answer_text should be in the format "campus.desc (campus.short_desc)"
                # if either campus.desc or campus.short_desc matches then true
                if campus.matches_eventbrite_campus(answer)
                  attendees << attendee
                end
              end
            end
          end

          attendees
        end

        
        def update_details_and_attendees_from_eventbrite
          local_event = self
          raise "Event has no eventbrite event id" unless local_event.eventbrite_id.present?
          original_synced_at = local_event.synced_at
          
          begin
            Rails.logger.info("Syncing Eventbrite event (#{Date.today}, event_id:#{local_event.id}, eventbrite_id:#{local_event.eventbrite_id})")
            eventbrite_user ||= EventBright.setup_from_initializer()
            eb_event = EventBright::Event.new(eventbrite_user, {:id => local_event.eventbrite_id})
            raise "Didn't get the Eventbrite event from Eventbrite" unless eb_event.present?
            
            local_event.title = eb_event.title
            local_event.description = eb_event.description
            local_event.register_url = eb_event.url
            local_event.start_date = eb_event.start_date
            local_event.end_date = eb_event.end_date
            
            eb_event.attendees.each { |attendee| ::EventAttendee.update_or_create_from_eventbrite(attendee) }
            
            # delete all event_attendees and person_event_attendees that aren't in the id's
            
            local_event.synced_at = Time.now
            local_event.save!
            
          rescue Exception => e
            Rails.logger.error("\nERROR SYNCING EVENTBRITE EVENT: \n\t#{e.class.to_s}\n\t#{e.message}\n")
            local_event.synced_at = original_synced_at
            local_event.save!
          end
        end
        
        
        module EventClassMethods
        end

      end
    end
  end
end
