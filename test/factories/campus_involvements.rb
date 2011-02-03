Factory.sequence :campusinvolvement_id do |n|
  n
end

Factory.sequence :campusinvolvement_person_id do |n|
  n
end

Factory.define :campusinvolvement, :class => CampusInvolvement do |c|
  c.id { Factory.next(:campusinvolvement_id) }
  c.person_id { Factory.next(:campusinvolvement_person_id) }
  c.campus_id '1'
  c.ministry_id '1'
  c.school_year_id '1'
end

Factory.define :campusinvolvement_2, :class => CampusInvolvement, :singleton => true do |c|
  c.id '1002'
  c.person_id '2000'
  c.campus_id '1'
  c.ministry_id '1'
  c.start_date '2009-10-10'
  c.school_year_id '1'
end

Factory.define :campusinvolvement_3, :class => CampusInvolvement, :singleton => true do |c|
  c.id '1003'
  c.person_id '50000'
  c.campus_id '1'
  c.ministry_id '1'
  c.school_year_id '1'
end

Factory.define :campusinvolvement_4, :class => CampusInvolvement, :singleton => true do |c|
  c.id '1004'
  c.person_id '2000'
  c.campus_id '2'
  c.ministry_id '1'
  c.school_year_id '1'
  c.start_date '2009-10-20'
end

Factory.define :campusinvolvement_5, :class => CampusInvolvement, :singleton => true do |c|
  c.id '1005'
  c.person_id '4001'
  c.campus_id '1'
  c.ministry_id '1'
  c.school_year_id '1'
end

Factory.define :campusinvolvement_6, :class => CampusInvolvement, :singleton => true do |c|
  c.id '1006'
  c.person_id '3000'
  c.campus_id '1'
  c.ministry_id '1'
  c.school_year_id '1'
end

Factory.define :campusinvolvement_7, :class => CampusInvolvement, :singleton => true do |c|
  c.id '1007'
  c.person_id '50000'
  c.campus_id '3'
  c.ministry_id '1'
  c.school_year_id '1'
  c.end_date Date.yesterday.to_date.to_s
end

Factory.define :campusinvolvement_8, :class => CampusInvolvement, :singleton => true do |c|
  c.id '1008'
  c.person_id '50000'
  c.campus_id '3'
  c.ministry_id '1'
  c.school_year_id '1'
  c.end_date nil
end

Factory.define :campusinvolvement_9, :class => CampusInvolvement, :singleton => true do |c|
  c.id '1009'
  c.person_id '4001' # user 5
  c.campus_id '2'
  c.ministry_id '1'
  c.school_year_id '1'
  c.end_date nil
end

Factory.define :campusinvolvement_10, :class => CampusInvolvement, :singleton => true do |c|
  c.id '1010'
  c.person_id '4002' # user 6
  c.campus_id '2'
  c.ministry_id '1'
  c.school_year_id '1'
  c.end_date nil
end

Factory.define :campusinvolvement_11, :class => CampusInvolvement, :singleton => true do |c|
  c.id '1011'
  c.person_id '111' # user 7
  c.campus_id '2'
  c.ministry_id '1'
  c.school_year_id '1'
  c.end_date nil
end

