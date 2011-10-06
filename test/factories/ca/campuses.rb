Factory.define :campus_1, :class => Campus, :singleton => true do |c|
  c.id '1'
  c.name 'University of California-Davis'
  c.short_desc 'UoCD'
  c.province_id '1'
  c.campus_website 'www.ucdavis.edu'
  c.campus_facebookgroup ''
  c.campus_gcxnamespace ''
  c.region_id '5'
  c.longitude '-121.75'
  c.latitude '38.54'
end

Factory.define :campus_2, :class => Campus, :singleton => true do |c|
  c.id '2'
  c.name 'Sacramento State'
  c.short_desc 'SS'
  c.province_id '1'
  c.campus_website 'www.csus.edu'
  c.campus_facebookgroup ''
  c.campus_gcxnamespace ''
  c.region_id '5'
  c.longitude '-121.424111'
  c.latitude '38.560222'
end

Factory.define :campus_3, :class => Campus, :singleton => true do |c|
  c.id '3'
  c.name 'Campus of Wyoming'
  c.short_desc 'CoW'
  c.province_id '2'
  c.campus_website ''
  c.campus_facebookgroup ''
  c.campus_gcxnamespace ''
  c.region_id '6'
  c.longitude '-105.581389'
  c.latitude '41.313056'
end

Factory.define :campus_4, :class => Campus, :singleton => true do |c|
  c.id '4'
  c.name 'National'
  c.short_desc 'Nat'
  c.province_id '0'
  c.campus_website 'powertochange.com'
  c.campus_facebookgroup ''
  c.campus_gcxnamespace ''
  c.region_id '4'
  c.longitude '-122.65758'
  c.latitude '49.1041'
end

