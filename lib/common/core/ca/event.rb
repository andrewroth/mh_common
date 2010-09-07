module Common
  module Core
    module Ca
      module Event
        def self.included(base)
          base.class_eval do
            def eventbrite_id() self.registrar_event_id end
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
                  if answer.slice(answer.rindex("("), answer.rindex(")")) == "(#{campus.short_desc})" ||
                     answer.slice(0, answer.rindex("(") - 1) == "#{campus.desc}"

                      attendees << attendee
                  end
                end
              end
            end

            attendees
          end
        end

      end
    end
  end
end
