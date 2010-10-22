puts %Q{requiring... './Riakpb'}
puts require './Riakpb'

puts "initializing Riakpb::Pabst..."

puts %Q{a = Riakpb::Pabst.new}
puts %Q{=> #{a = Riakpb::Pabst.new}}

client_id = nil;
server_info = nil;
keys = nil;
key = nil;
put_key = nil;
buckets = nil;

[ %Q{client_id = a.get_client_id},
  %Q{client_id.class},
  %Q{client_id.size},
  %Q{server_info = a.server_info},
  %Q{server_info.class},
  %Q{server_info.size},
  %Q{keys = a.list_keys "tstBucket"},
  %Q{keys.class},
  %Q{keys.length},
  %Q{key = a.get_key "tstBucket", "tstKey"},
  %Q{key.class},
  %Q{key.length},
  %Q{a.put_key "tstBucket", "tstKey3", {:value => "threezy peazy!", :content_type => "crap"}, nil, 1, 1, true},
  %Q{buckets = a.list_buckets}
].each do |crap_test|
  
  puts crap_test
  puts %Q{=> #{eval crap_test}}
  
end
