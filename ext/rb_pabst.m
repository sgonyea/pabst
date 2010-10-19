#import "rb_pabst.h"
/*
VALUE rb_ping_request(VALUE self) {
  RiakProtobuf   *riakpb  = Get_RiakProtobuf(self);
  BOOL response;
}
*/
VALUE rb_get_client_id_request(VALUE self) {
  OFAutoreleasePool  *pool    = [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb  = Get_RiakProtobuf(self);
  OFNumber           *client_id;
  VALUE               rb_client_id;

  client_id     = [[riakpb getClientId] autorelease];
  rb_client_id  = [client_id toRuby]; // rb_str_new([client_id cString], [client_id cStringLength]);

  [pool release];
  return rb_client_id;
}

VALUE rb_get_server_info_request(VALUE self) {
  OFAutoreleasePool  *pool    = [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb  = Get_RiakProtobuf(self);
  OFDictionary       *server_info;
  VALUE               rb_server_info;

  server_info     = [[riakpb getServerInfoRequest] autorelease];
  rb_server_info  = [server_info toRuby];

  [pool release];
  return rb_server_info;
}

VALUE rb_get_key_request(VALUE self, VALUE bucket_name, VALUE key_name) {
  OFAutoreleasePool  *pool        = [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb      = Get_RiakProtobuf(self);
  VALUE               rb_key      = rb_hash_new(),
                      rb_vclock   = Qnil,
                      rb_contents = Qnil;
  OFDictionary       *key;
  OFString           *vclock;
  OFDataArray        *contents;

  // @TODO: Allow the quorum to be set
  key         = [[riakpb getKey:[OFString stringWithCString:RSTRING_PTR(key_name)
                                                     length:RSTRING_LEN(key_name)]
                     fromBucket:[OFString stringWithCString:RSTRING_PTR(bucket_name)
                                                     length:RSTRING_LEN(bucket_name)]
                         quorum:nil] autorelease];

  vclock      = [key objectForKey:@"vclock"];
  contents    = [key objectForKey:@"content"];

  if (vclock)   rb_vclock   = [vclock toRuby];
  if (contents) rb_contents = [contents toRuby];

  rb_hash_aset( rb_key, ID2SYM(rb_intern("vclock")),    (rb_vclock)   ? rb_vclock
                                                                      : Qnil);
  rb_hash_aset( rb_key, ID2SYM(rb_intern("contents")),  (rb_contents) ? rb_contents
                                                                      : Qnil);
  [pool release];
  return rb_key;
}

VALUE rb_put_key_request(VALUE self,      VALUE bucket_name,  VALUE key_name,   VALUE content, 
                         VALUE rb_vclock, VALUE rb_quorum,    VALUE rb_commit,  VALUE return_body) {

  Check_Type(bucket_name, T_STRING);
  Check_Type(key_name,    T_STRING);
  Check_Type(content,     T_HASH);

  if(rb_vclock != Qnil)
    Check_Type(rb_vclock, T_STRING);
  if(rb_quorum != Qnil)
    Check_Type(rb_quorum, T_FIXNUM);
  if(rb_commit != Qnil)
    Check_Type(rb_commit, T_FIXNUM);

  OFAutoreleasePool    *pool        = [[OFAutoreleasePool alloc] init];
  RiakProtobuf         *riakpb      = Get_RiakProtobuf(self);
  VALUE                 rb_key      = rb_hash_new(),
                        rb_vclock   = Qnil,
                        rb_contents = Qnil;
  OFDictionary         *key         = nil;
  OFMutableDictionary  *content     = [[OFMutableDictionary alloc] init];
  int                   quorum      = NUM2INT(rb_quorum),
                        commit      = NUM2INT(rb_commit);
  BOOL                  returnBody  = YES;

  if(Qfalse == return_body)
    returnBody = NO;

  // @TODO: Check the Ruby encoding and set it accordingly
  key = [[riakpb putKey:[OFString stringWithCString:RSTRING_PTR(key_name)
                                             length:RSTRING_LEN(key_name)]
               inBucket:[OFString stringWithCString:RSTRING_PTR(bucket_name)
                                             length:RSTRING_LEN(bucket_name)]
                 vClock:[OFString stringWithCString:RSTRING_PTR(key_name)
                                             length:RSTRING_LEN(key_name)]
                content:
                 quorum:quorum
                 commit:commit
             returnBody:returnBody] autorelease];
}

VALUE rb_list_keys_request(VALUE self, VALUE bucket_name) {
  OFAutoreleasePool  *pool    = [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb  = Get_RiakProtobuf(self);
  OFDataArray        *keys;
  VALUE               rb_keys;

  // @TODO: Ensure that bucket name is a String, or call :to_s. Raise intelligent exception if that fails
  // @TODO: Figure out how to get the encoding of the String. Assumption is a UTF-8 encoding, for now.
  keys        = [[riakpb listKeysInBucket:[OFString stringWithCString:RSTRING_PTR(bucket_name)
                                                               length:RSTRING_LEN(bucket_name)]]
                 autorelease];

  rb_keys     = [keys toRuby];

  [pool release];
  return rb_keys;
}

