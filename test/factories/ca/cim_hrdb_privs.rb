Factory.define :cimhrdbpriv_1, :class => CimHrdbPriv, :singleton => true do |c|
  c.priv_id '1'
  c.priv_accesslevel 'HRDB Super Admin'
end

Factory.define :cimhrdbpriv_2, :class => CimHrdbPriv, :singleton => true do |c|
  c.priv_id '2'
  c.priv_accesslevel 'HRDB Campus Admin'
end
