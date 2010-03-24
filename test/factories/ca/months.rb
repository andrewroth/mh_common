Factory.define :month_1, :class => Month, :singleton => true do |m|
  m.month_id '1'
  m.month_desc 'January 2010'
  m.month_number '1'
  m.year_id '1'
  m.month_calendaryear '2010'
  m.semester_id '11'
end

Factory.define :month_2, :class => Month, :singleton => true do |m|
  m.month_id '2'
  m.month_desc 'February 2010'
  m.month_number '2'
  m.year_id '1'
  m.month_calendaryear '2010'
  m.semester_id '11'
end

Factory.define :month_3, :class => Month, :singleton => true do |m|
  m.month_id '3'
  m.month_desc 'March 2010'
  m.month_number '3'
  m.year_id '1'
  m.month_calendaryear '2010'
  m.semester_id '11'
end
