Factory.define :year_1, :class => Year, :singleton => true do |m|
  m.year_id '1'
  m.year_desc '2009-2010'
end

Factory.define :year_2, :class => Year, :singleton => true do |m|
  m.year_id '2'
  m.year_desc '2010-2011'
end
