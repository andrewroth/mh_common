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
            
            attendee_ids = []
            eb_event.attendees.each do |attendee|
              attendee_ids << attendee.id
              ::EventAttendee.update_or_create_from_eventbrite(attendee)
            end
            
            # it's possible that an attendee cancelled or is otherwise no longer attending the event
            # so delete all attendees in local database that aren't on eventbrite anymore
            cancelled_attendees = ::EventAttendee.all(:conditions => ["event_id = ? and ticket_id not in (?)", local_event.id, attendee_ids])
            cancelled_event_attendee_ids = cancelled_attendees.collect{|a| a.id}
            ::PersonEventAttendee.delete_all(["event_attendee_id in (?)", cancelled_event_attendee_ids])
            ::EventAttendee.delete_all(["id in (?)", cancelled_event_attendee_ids])
            
            local_event.synced_at = Time.now
            local_event.save!
            
          rescue Exception => e
            Rails.logger.error("\nERROR SYNCING EVENTBRITE EVENT: \n\t#{e.class.to_s}\n\t#{e.message}\n")
            local_event.synced_at = original_synced_at
            local_event.save!
          end
        end
        
        
        module EventClassMethods
          
          def sync_unsynced_events(force_sync_all = false)
            # calling this may take some time, use a delayed job
            
            unless force_sync_all
              # get all events that haven't been synced recently or ever
              sync_delay = eventbrite[:num_days_sync_delay].to_i.days.ago.in_time_zone('UTC')
              sync_events = ::Event.all(:conditions => ["synced_at is null or synced_at < ?", sync_delay])
              
              # ignore events that are closed and already synced
              sync_events = sync_events.select { |e| e.end_date.blank? || e.synced_at.blank? || e.synced_at < e.end_date+eventbrite[:num_days_until_event_closed_after_completed].days }
            else
              sync_events = ::Event.all
            end
            
            sync_events.each { |e| e.update_details_and_attendees_from_eventbrite }
          end
          
        end

      end
    end
  end
end
