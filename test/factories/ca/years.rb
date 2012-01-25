Factory.define :year_1, :class => Year, :singleton => true do |m|
  m.year_id '1'
  m.year_desc '2009-2010'
  m.year_number 2009
end

Factory.define :year_2, :class => Year, :singleton => true do |m|
  m.year_id '2'
  m.year_desc '2010-2011'
  m.year_number 2010
end

Factory.define :year_3, :class => Year, :singleton => true do |m|
  m.year_id '3'
  m.year_desc '2011-2012'
  m.year_number 2011
end
