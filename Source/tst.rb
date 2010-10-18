puts %Q{requiring... './Riakpb'}
puts require './Riakpb'

puts "initializing Riakpb::Pabst..."

puts "a = Riakpb::Pabst.new"
puts "=> #{a = Riakpb::Pabst.new}"

puts %Q{client_id = a.get_client_id}
puts "=> #{client_id = a.get_client_id}"

puts %Q{client_id.class}
puts "=> #{client_id.class}"

puts %Q{client_id.size}
puts "=> #{client_id.size}"

puts %Q{server_info = a.server_info}
puts "=> #{server_info = a.server_info}"

puts %Q{server_info.class}
puts "=> #{server_info.class}"

puts %Q{server_info.size}
puts "=> #{server_info.size}"

puts %Q{keys = a.list_keys "tstBucket"}
puts "=> #{keys = a.list_keys 'tstBucket'}"

puts %Q{keys.class}
puts "=> #{keys.class}"

puts %Q{keys.length}
puts "=> #{keys.length}"

puts %Q{key = a.get_key "tstBucket", "tstKey"}
puts "=> #{key = a.get_key 'tstBucket', 'tstKey'}"

puts %Q{key.class}
puts "=> #{key.class}"

puts %Q{key.length}
puts "=> #{key.length}"

