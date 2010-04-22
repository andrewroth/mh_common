Factory.define :assignment_1, :class => Assignment, :singleton => true do |c|
  c.assignment_id '1'
  c.person_id '50000'
  c.campus_id '1'
  c.assignmentstatus_id '3'
end

Factory.define :assignment_2, :class => Assignment, :singleton => true do |c|
  c.assignment_id '2'
  c.person_id '50000'
  c.campus_id '2'
  c.assignmentstatus_id '2'
end

Factory.define :assignment_3, :class => Assignment, :singleton => true do |c|
  c.assignment_id '3'
  c.person_id '50000'
  c.campus_id '3'
  c.assignmentstatus_id '1'
end

Factory.define :assignment_4, :class => Assignment, :singleton => true do |c|
  c.assignment_id '4'
  c.person_id '2000'
  c.campus_id '1'
  c.assignmentstatus_id '7'
end

Factory.define :assignment_5, :class => Assignment, :singleton => true do |c|
  c.assignment_id '5'
  c.person_id '3000'
  c.campus_id '1'
  c.assignmentstatus_id '4'
end

Factory.define :assignment_6, :class => Assignment, :singleton => true do |c|
  c.assignment_id '6'
  c.person_id '1'
  c.campus_id '1'
  c.assignmentstatus_id '1'
end
