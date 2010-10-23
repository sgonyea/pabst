require 'benchmark'
require './Riakpb'
require 'riakpb'
require 'riak'

iterations  = [100, 1000]

riak_objc   = Riakpb::Pabst.new
riak_rbpb   = Riakpb::Client.new
riak_ripl   = Riak::Client.new

ripl_buck   = riak_ripl["tstBucketRipl"]

iterations.each do |iter|
  Benchmark.bmbm do |x|
# Get Client ID
    x.report("ObjC:    Get Client ID") {
      iter.times{ riak_objc.get_key      "tstBucket", "tstKey" }
    }
#    x.report("Riakpb:  Get Client ID") {
#      iter.times{ riak_rbpb.get_request  "tstBucket", "tstKey" }
#    }
    x.report("Ripple:  Get Client ID") {
      iter.times{ riak_ripl.bucket(      "tstBucket")["tstKey"]}
    }

# Get Key
    x.report("ObjC:    Get Key") {
      iter.times{ riak_objc.get_key      "tstBucket", "tstKey" }
    }
#    x.report("Riakpb:  Get Key") {
#      iter.times{ riak_rbpb.get_request  "tstBucket", "tstKey" }
#    }
    x.report("Ripple:  Get Key") {
      iter.times{ riak_ripl.bucket(      "tstBucket")["tstKey"]}
    }

# Put Key
    x.report("ObjC:    Put Key") {
      iter.times{|n| riak_objc.put_key      "tstBucketObjC", "tstKey#{n}", {:value => "RAWR OBJC #{n}", :content_type => "application/json"}, nil, 1, 1, true }
    }
#    x.report("Riakpb:  Put Key") {
#      iter.times{|n| riak_rbpb.put_request({:bucket => "tstBucketRbPb", :key => "tstKey#{n}", :content => {:value => "RAWR RBPB #{n}", :content_type => "application/json"}, :w => 1, :dw => 1}) }
#    }
    x.report("Ripple:  Put Key") {
      iter.times{|n| (Riak::RObject.new(ripl_buck, "tstKey#{n}").tap {|ripl| ripl.data = "RAWR RIPL #{n}"; ripl.content_type = "application/json";}).store(:w => 1, :dw => 1, :r => 1) }
    }

# Get Bucket Props

# Set Bucket Props


  end
end