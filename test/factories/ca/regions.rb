Factory.define :region_1, :class => Region, :singleton => true do |c|
  c.id '1'
  c.reg_desc 'Ontario & Maritimes'
  c.country_id '2'
end

Factory.define :region_2, :class => Region, :singleton => true do |c|
  c.id '2'
  c.reg_desc 'Quebec'
  c.country_id '2'
end

Factory.define :region_3, :class => Region, :singleton => true do |c|
  c.id '3'
  c.reg_desc 'Western Canada'
  c.country_id '2'
end

