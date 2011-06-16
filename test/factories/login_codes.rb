
Factory.define :login_code_1, :class => LoginCode, :singleton => true  do |l|
  l.id '1'
  l.acceptable '1'
  l.times_used '0'
  l.code '5a12855a-aa70-4990-b757-6bf02ec7a30b'
  l.expires_at nil
end

