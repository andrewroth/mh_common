Factory.define :gender_0, :class => Gender, :singleton => true do |c|
  c.id '0'
  c.gender_desc '???'
end

Factory.define :gender_1, :class => Gender, :singleton => true do |c|
  c.id '1'
  c.gender_desc 'Male'
end

Factory.define :gender_2, :class => Gender, :singleton => true do |c|
  c.id '2'
  c.gender_desc 'Female'
end
