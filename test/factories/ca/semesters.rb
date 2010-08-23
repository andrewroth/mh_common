Factory.define :semester_10, :class => Semester, :singleton => true do |p|
  p.semester_id '10'
  p.semester_desc 'Fall 2009'
  p.semester_startDate '2009-09-01'
  p.year_id '1'
end

Factory.define :semester_11, :class => Semester, :singleton => true do |p|
  p.semester_id '11'
  p.semester_desc 'Winter 2010'
  p.semester_startDate '2010-01-01'
  p.year_id '1'
end

Factory.define :semester_12, :class => Semester, :singleton => true do |p|
  p.semester_id '12'
  p.semester_desc 'Summer 2010'
  p.semester_startDate '2010-05-01'
  p.year_id '1'
end

Factory.define :semester_13, :class => Semester, :singleton => true do |p|
  p.semester_id '13'
  p.semester_desc 'Fall 2010'
  p.semester_startDate '2010-09-01'
  p.year_id '2'
end
