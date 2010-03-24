Factory.define :accountadminaccessgroup_1, :class => AccountadminAccessgroup, :singleton => true do |c|
  c.accessgroup_id '1'
  c.accesscategory_id '1'
  c.accessgroup_key '[accessgroup_key1]'
  c.english_value 'All'
end

Factory.define :accountadminaccessgroup_2, :class => AccountadminAccessgroup, :singleton => true do |c|
  c.accessgroup_id '36'
  c.accesscategory_id '4'
  c.accessgroup_key '[accessgroup_key36]'
  c.english_value 'Nav Bar'
end
