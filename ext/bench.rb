require 'benchmark'
require './Riakpb'
require 'riakpb'
require 'riak'

iterations  = [100, 1000];

riak_objc   = Riakpb::Pabst.new
riak_rbpb   = Riakpb::Client.new
riak_ripl   = Riak::Client.new

iterations.each do |iter|
  Benchmark.bmbm do |x|
# Get Client ID
    x.report("ObjC:    Get Client ID") {
      iter.times{ riak_objc.get_key      "tstBucket", "tstKey" }
    }
    x.report("Riakpb:  Get Client ID") {
      iter.times{ riak_rbpb.get_request  "tstBucket", "tstKey" }
    }
    x.report("Ripple:  Get Client ID") {
      iter.times{ riak_ripl.bucket(      "tstBucket")["tstKey"]}
    }

# Server Info
    x.report("ObjC:    Get Server Info") {
      iter.times{ riak_objc.server_info }
    }
    x.report("Riakpb:  Get Server Info") {
      iter.times{ riak_rbpb. }
    }
    x.report("Ripple:  Get Server Info") {
      iter.times{ riak_ripl. }
    }

# Get Key
    x.report("ObjC:    Get Key") {
      iter.times{ riak.get_key      "tstBucket", "tstKey" }
    }
    x.report("Riakpb:  Get Key") {
      iter.times{ riak_rbpb.get_request  "tstBucket", "tstKey" }
    }
    x.report("Ripple:  Get Key") {
      iter.times{ riak_ripl.bucket(      "tstBucket")["tstKey"]}
    }

# Put Key
    x.report("ObjC:    ") {
      iter.times{ riak_objc. }
    }
    x.report("Riakpb:  ") {
      iter.times{ riak_rbpb. }
    }
    x.report("Ripple:  ") {
      iter.times{ riak_ripl. }
    }

# Get Bucket Props

# Set Bucket Props


  end
end