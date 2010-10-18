Pabst: Protocol Buffers for Riak
================================

Pabst is a cross-platform Ruby Extension, written in both Objective-C and Objective-C++.  Weird, right?  Sure, but Objective-C feels like a very natural language for writing Ruby Extensions.  The "Objective-C++" part is just ObjC wrapped around some C++ library.  It lets me call the C++ instance methods while keeping things C/ObjC-ish.

[ObjFW][objfw] ([mirror][objfw-mirror]) is at the heart of this extension, and is written by Jonathan Schleifer.  It's an excellent, cross-platform Objective-C library and is something I believe could benefit the Ruby community.

How to Use
==========

1. Install ObjFW
      git:
            git clone git://github.com/aitrus/objfw.git
            cd objfw
            ./autogen.sh
            ./configure
            make
            [sudo] make install
    Mercurial (most up-to-date repo):
            hg clone https://webkeks.org/hg/objfw
            cd objfw
            ./autogen.sh
            ./configure
            make
            [sudo] make install
2. Install [Google Protocol Buffers][protobuf] ([Download List][protobuf-dl])
    This should be available via whichever package manager you use. I use Mac Homebrew, and it's there.
3. Get the extension:
    * Clone this repo:

            git clone git://github.com/aitrus/pabst.git

    * Build the extension

            cd pabst/Source
            ruby extconf.rb
            make

    * Enter irb and use what limited commands are available :)

            > irb
            require './Riakpb'
            pabst       = Riakpb::Pabst.new
            client_id   = pabst.get_client_id
            server_info = pabst.server_info
            keys        = pabst.list_keys 'tstBucket'
            key         = pabst.get_key 'tstBucket', 'tstKey'


There's a lot that is yet to be done. Please stay tuned and watch this repo if you're at all interested.

[objfw]:        https://webkeks.org/objfw/                        "ObjFW Project Page"
[objfw-mirror]: http://github.com/aitrus/objfw                    "ObjFW Github Mirror"
[protobuf]:     http://code.google.com/p/protobuf/                "Google Protocol Buffers"
[protobuf-dl]:  http://code.google.com/p/protobuf/downloads/list  "Google Protocol Buffers Download Page"
