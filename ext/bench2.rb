require 'benchmark'
require './Riakpb'
require 'riakpb'
require 'riak'

Benchmark.bmbm do |x|
  x.report("run: ObjC") {
    riak  = Riakpb::Pabst.new
    key   = riak.get_key "tstBucket", "tstKey"
  }
  x.report("run: Riakpb") {
    riak  = Riakpb::Client.new
    key   = riak.get_request("tstBucket", "tstKey")
  }
  x.report("run: Ripple") {
    riak  = Riak::Client.new
    key   = riak.bucket("tstBucket")["tstKey"]
  }
end