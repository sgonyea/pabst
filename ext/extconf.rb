# mkmf: http://ruby-doc.org/stdlib/libdoc/mkmf/rdoc/index.html
require 'mkmf'

# The Pabst Ruby Extension
extension_name  = 'Riakpb'

riak_proto_file = "riakclient.proto"
riak_cc_file    = "riakclient.pb.cc"
riak_mm_file    = "riakclient.pb.mm"

def command(cmd)
  $stderr.puts "execute '#{cmd}' ..."
  raise(RuntimeError, cmd) unless system(cmd)
  $stderr.puts "execute '#{cmd}' done"
end

begin
  command "protoc --cpp_out=. #{riak_proto_file}"
rescue RuntimeError => e
  puts "Error, please install Google's Protocol Buffers (~>2.3.0 suggested). at:"
  puts "  ->  http://code.google.com/p/protobuf/"

  case RUBY_PLATFORM
  when /linux/        then  puts "Please check to see if your distro has protobuf pkg"
  when /darwin/       then  puts "Which is also available through the Homebrew Package Manager, for Mac OS X"
                            puts "  ->  http://mxcl.github.com/homebrew/"
                            puts "  >> `brew install protobuf`"
  end

  puts "Error message: #{e}"
end
command "mv -f #{riak_cc_file} #{riak_mm_file}"

dir_config(extension_name)

# Compilation Flags. Not absolutely necessary, but may save you a headache.

#$CFLAGS        << "  -fexceptions -fobjc-exceptions -fconstant-string-class=OFConstantString -fno-constant-cfstrings -fblocks"
#$CPPFLAGS      << " -I/usr/local/include  -fexceptions -fobjc-exceptions -fconstant-string-class=OFConstantString -fno-constant-cfstrings -fblocks"
objc_flags      = `objfw-config --objcflags`.chomp
$CFLAGS        << objc_flags + `objfw-config --cflags`.chomp
$CPPFLAGS      << objc_flags + `objfw-config --cppflags`.chomp
$DLDFLAGS      << " -lobjc -lprotobuf -lobjfw "
$DLDFLAGS      << `objfw-config --libs`.chomp
$DLDFLAGS      << `objfw-config --reexport`.chomp
CXX_EXT        << "mm"
SRC_EXT        << "mm"

# Do the work
create_makefile(extension_name)

command "mv -f Makefile Makefile.bak"
command "sed -e 's/^\.c\.o:$/\.m\.o:/' Makefile.bak > Makefile"
command "rm Makefile.bak"
