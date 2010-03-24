Factory.define :accountadminvieweraccessgroup_1, :class => AccountadminVieweraccessgroup, :singleton => true do |c|
  c.vieweraccessgroup_id '1'
  c.viewer_id '1'
  c.accessgroup_id '1'
end

Factory.define :accountadminvieweraccessgroup_2, :class => AccountadminVieweraccessgroup, :singleton => true do |c|
  c.vieweraccessgroup_id '2'
  c.viewer_id '1'
  c.accessgroup_id '36'
end

Factory.define :accountadminvieweraccessgroup_3, :class => AccountadminVieweraccessgroup, :singleton => true do |c|
  c.vieweraccessgroup_id '3'
  c.viewer_id '2'
  c.accessgroup_id '1'
end

Factory.define :accountadminvieweraccessgroup_4, :class => AccountadminVieweraccessgroup, :singleton => true do |c|
  c.vieweraccessgroup_id '4'
  c.viewer_id '3'
  c.accessgroup_id '36'
end
