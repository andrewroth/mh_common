
Factory.define :login_code_1, :class => LoginCode, :singleton => true  do |l|
  l.id '1'
  l.acceptable '1'
  l.times_used '0'
  l.code '5a12855a-aa70-4990-b757-6bf02ec7a30b'
  l.expires_at nil
end

Factory.define :login_code_2, :class => LoginCode, :singleton => true  do |l|
  l.id '2'
  l.acceptable '1'
  l.times_used '0'
  l.code '280ab349-bec3-4294-b77e-42045bb32b2e'
  l.expires_at nil
end

