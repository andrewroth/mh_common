Factory.define :event_1, :class => Event, :singleton => true do |e|
  e.id '1'
  e.registrar_event_id '1111111'
  e.event_group_id '1'
  e.register_url 'event_1.register.url'
  e.title 'Event One'
  e.description 'the first event, the best event, the only event you need to be at'
  e.start_date DateTime.new(2010, 6, 1, 9)
  e.end_date DateTime.new(2010, 6, 7, 21)
end
