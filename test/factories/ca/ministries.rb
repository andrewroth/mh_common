Factory.define :ministry_1, :class => Ministry, :singleton => true do |m|
  m.ministry_id '1'
  m.ministry_name 'YFC'
  m.ministry_abbrev 'YFC'
end

Factory.define :ministry_2, :class => Ministry, :singleton => true do |m|
  m.ministry_id '2'
  m.ministry_name 'Chicago Metro'
  m.ministry_abbrev 'CM'
end

Factory.define :ministry_3, :class => Ministry, :singleton => true do |m|
  m.ministry_id '3'
  m.ministry_name 'DG'
  m.ministry_abbrev 'DG'
end

Factory.define :ministry_4, :class => Ministry, :singleton => true do |m|
  m.ministry_id '4'
  m.ministry_name 'top'
  m.ministry_abbrev 'TOP'
end

Factory.define :ministry_5, :class => Ministry, :singleton => true do |m|
  m.ministry_id '7'
  m.ministry_name 'under_top'
  m.ministry_abbrev 'UTOP'
end

Factory.define :ministry_6, :class => Ministry, :singleton => true do |m|
  m.ministry_id '5'
  m.ministry_name Cmt::CONFIG[:default_ministry_name] || 'No Ministry'
  m.ministry_abbrev 'DEF'
end

Factory.define :ministry_7, :class => Ministry, :singleton => true do |m|
  m.ministry_id '6'
  m.ministry_name 'Check My Roles'
  m.ministry_abbrev 'CMR'
end
