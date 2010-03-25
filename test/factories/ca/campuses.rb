Factory.define :campus_1, :class => Campus, :singleton => true do |c|
  c.id '1'
  c.name 'University of California-Davis'
  c.short_desc 'UoCD'
  c.province_id '1'
  c.campus_facebookgroup ''
  c.campus_gcxnamespace ''
  c.region_id '5'
end

Factory.define :campus_2, :class => Campus, :singleton => true do |c|
  c.id '2'
  c.name 'Sacramento State'
  c.short_desc 'SS'
  c.province_id '1'
  c.campus_facebookgroup ''
  c.campus_gcxnamespace ''
  c.region_id '5'
end

Factory.define :campus_3, :class => Campus, :singleton => true do |c|
  c.id '3'
  c.name 'Campus of Wyoming'
  c.short_desc 'CoW'
  c.province_id '2'
  c.campus_facebookgroup ''
  c.campus_gcxnamespace ''
  c.region_id '6'
end

Factory.define :campus_4, :class => Campus, :singleton => true do |c|
  c.id '4'
  c.name 'National'
  c.short_desc 'Nat'
  c.province_id '0'
  c.campus_facebookgroup ''
  c.campus_gcxnamespace ''
  c.region_id '4'
end

