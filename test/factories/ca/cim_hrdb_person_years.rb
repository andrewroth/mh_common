Factory.define :cimhrdbpersonyear_1, :class => CimHrdbPersonYear, :singleton => true do |c|
  c.id '1'
  c.person_id '50000'
  c.year_id '3'
  c.grad_date '05/01/2020'
end

Factory.define :cimhrdbpersonyear_2, :class => CimHrdbPersonYear, :singleton => true do |c|
  c.id '2'
  c.person_id '50000'
  c.year_id '9'
  c.grad_date '00/00/0000'
end

