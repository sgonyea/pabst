require 'benchmark'

Benchmark.bmbm do |x|
  x.report("load+run: ObjC") {
    require './Riakpb'
    riak  = Riakpb::Pabst.new
    key   = riak.get_key "tstBucket", "tstKey"
  }
  x.report("load+run: Riakpb") {
    require 'riakpb'
    riak  = Riakpb::Client.new
    key   = riak.get_request("tstBucket", "tstKey")
  }
  require 'riak'
  x.report("run: Ripple") {
    riak  = Riak::Client.new
    key   = riak.bucket("tstBucket")["tstKey"]
  }
end
