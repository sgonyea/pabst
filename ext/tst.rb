#!/usr/local/rvm/rubies/ruby-1.9.2-p0/bin/ruby

require 'benchmark'
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

@commands = [ ["client_id",   %Q{client_id = a.get_client_id}],
              ["server_info", %Q{server_info = a.server_info}],
              ["get_key",     %Q{key = a.get_key "tstBucket", "tstKey"}],
              ["get_bucket",  %Q{bprops = a.get_bucket "tstBucket"}],
              ["put_key",     %Q{a.put_key "tstBucket", "tstKey7", {:value => "KILL YOUR PARENTS", :content_type => "crap"}, nil, 1, 1, true}],
              ["set_bucket",  %Q{bset = a.set_bucket "tstBucket", 3, false}]
            ]
list_cmds = [ ["list_keys",   %Q{keys = a.list_keys "tstBucket"}],
              ["list_buckets",%Q{buckets = a.list_buckets}]
            ]

#Benchmark.bmbm do |x|

@commands.each do |message, command|
#    x.report("100  #{message}") {
#      100.times{ eval command }
#    }
    puts %Q{#{message}:}
    puts %Q{ #{command}}
    puts %Q{=> #{eval command}}
  end
#end

Benchmark.bmbm do |x|
  @commands.each do |message, command|
    x.report("1000 #{message}") {
      1000.times{ eval command }
    }
  end
end # Benchmark
