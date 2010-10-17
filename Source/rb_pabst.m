#import "rb_pabst.h"
/*
VALUE rb_ping_request(VALUE self) {
  RiakProtobuf   *riakpb  = Get_RiakProtobuf(self);
  BOOL response;
  
}
*/
VALUE rb_get_client_id_request(VALUE self) {
  RiakProtobuf   *riakpb  = Get_RiakProtobuf(self);
  OFNumber       *client_id;
  VALUE           rb_client_id;

  client_id     = [riakpb clientIdRequest];
  rb_client_id  = [client_id toRuby]; // rb_str_new([client_id cString], [client_id cStringLength]);

  [client_id release];

  return rb_client_id;
}

VALUE rb_get_server_info_request(VALUE self) {
  RiakProtobuf   *riakpb  = Get_RiakProtobuf(self);
  OFDictionary   *server_info;
  VALUE           rb_server_info;

  server_info     = [riakpb getServerInfoRequest];

  rb_server_info  = [server_info toRuby];

  [server_info release];

  return rb_server_info;
}

VALUE rb_get_key_request(VALUE self, VALUE bucket_name, VALUE key_name) {
  RiakProtobuf   *riakpb  = Get_RiakProtobuf(self);
  OFDictionary   *key;
  OFString       *bucketName;
  OFString       *keyName;
  OFString       *vclock;
  OFDataArray    *content;
  VALUE           rb_key      = rb_hash_new();
  VALUE           rb_contents;
  size_t          iter;

  bucketName  = [OFString stringWithCString:RSTRING_PTR(bucket_name)
                                     length:RSTRING_LEN(bucket_name)];

  keyName     = [OFString stringWithCString:RSTRING_PTR(key_name)
                                     length:RSTRING_LEN(key_name)];

  key         = [riakpb getFromBucket:bucketName atKey:keyName quorum:nil];
  vclock      = [key objectForKey:@"vclock"];
  content     = [key objectForKey:@"content"];

  rb_hash_aset( rb_key,
                ID2SYM(rb_intern("vclock")),
                (vclock) ? [vclock toRuby]
                          : Qnil);

  rb_hash_aset( rb_key,
                ID2SYM(rb_intern("content")),
                (content) ? [content toRuby]
                          : Qnil);

  [key release];
  return rb_key;
}

VALUE rb_list_keys_request(VALUE self, VALUE bucket_name) {
  RiakProtobuf   *riakpb  = Get_RiakProtobuf(self);
  OFString       *bucketName;
  OFMutableArray *keys;
  VALUE           rb_keys;

  // @TODO: Ensure that 'bucket_name' is a String, or call :to_s. Raise intelligent exception if that fails
  // @TODO: Figure out how to get the encoding of the String. Assumption is a UTF-8 encoding, for now.
  bucketName  = [OFString stringWithCString:RSTRING_PTR(bucket_name)
                                     length:RSTRING_LEN(bucket_name)];

  keys        = [riakpb listKeysInBucket:bucketName];
  rb_keys     = [keys toRuby];

  [keys release];

  return rb_keys;
}


