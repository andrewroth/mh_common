Factory.define :title_1, :class => Title, :singleton => true do |p|
  p.id '1'
  p.desc 'Mr.'
end

Factory.define :title_2, :class => Title, :singleton => true do |p|
  p.id '2'
  p.desc 'Ms.'
end

Factory.define :title_3, :class => Title, :singleton => true do |p|
  p.id '3'
  p.desc 'Mrs.'
end

Factory.define :title_4, :class => Title, :singleton => true do |p|
  p.id '4'
  p.desc 'Dr.'
end

Factory.define :title_5, :class => Title, :singleton => true do |p|
  p.id '5'
  p.desc 'Rev.'
end
