Factory.define :event_1_attendee_1, :class => EventAttendee, :singleton => true do |e|
  e.id '1'
  e.event_id '1'
  e.ticket_id '11'
  e.ticket_update_at DateTime.new(2010, 5, 1, 9)
  e.email 'fred@uscm.org'
  e.first_name 'Fred'
  e.last_name 'Anderson'
  e.gender 'Male'
  e.campus 'University of California-Davis (UoCD)'
  e.year_in_school '1st Year (Undergrad)'
  e.home_phone '111-111-home'
  e.cell_phone '111-111-cell'
  e.work_phone '111-111-work'
end

Factory.define :event_1_attendee_2, :class => EventAttendee, :singleton => true do |e|
  e.id '2'
  e.event_id '1'
  e.ticket_id '12'
  e.ticket_update_at DateTime.new(2010, 4, 12, 10)
  e.email 'someone.not.in.db@3r98hjewfsdfk4wiuh.com'
  e.first_name 'Someone'
  e.last_name 'Somewhere'
  e.gender 'Female'
  e.campus 'University of California-Davis (UoCD)'
  e.year_in_school 'Other'
  e.home_phone '222-222-2222'
  e.cell_phone ''
  e.work_phone ''
end
