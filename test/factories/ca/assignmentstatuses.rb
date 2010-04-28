Factory.define :assignmentstatus_1, :class => Assignmentstatus, :singleton => true do |c|
  c.id '1'
  c.desc 'Current Student'
end

Factory.define :assignmentstatus_2, :class => Assignmentstatus, :singleton => true do |c|
  c.id '2'
  c.desc 'Alumni'
end

Factory.define :assignmentstatus_3, :class => Assignmentstatus, :singleton => true do |c|
  c.id '3'
  c.desc 'Staff'
end

Factory.define :assignmentstatus_4, :class => Assignmentstatus, :singleton => true do |c|
  c.id '4'
  c.desc 'Attended'
end

Factory.define :assignmentstatus_5, :class => Assignmentstatus, :singleton => true do |c|
  c.id '5'
  c.desc 'Staff Alumni'
end

Factory.define :assignmentstatus_6, :class => Assignmentstatus, :singleton => true do |c|
  c.id '6'
  c.desc 'Campus Alumni'
end

Factory.define :assignmentstatus_0, :class => Assignmentstatus, :singleton => true do |c|
  c.id '7'
  c.desc 'Unknown Status'
end
