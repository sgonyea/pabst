#import "rb_pabst.h"

VALUE rb_list_keys_request(VALUE self, VALUE bucket_name) {
  RiakProtobuf   *riakpb  = Get_RiakProtobuf(self);
  OFString       *bucket;
  OFMutableArray *keys;
  VALUE           rb_keys;

  // @TODO: Ensure that 'bucket_name' is a String, or call :to_s. Raise intelligent exception if that fails
  // @TODO: Figure out how to get the encoding of the String. Assumption is a UTF-8 encoding, for now.
  bucket      = [OFString stringWithCString:RSTRING_PTR(bucket_name)
                                     length:RSTRING_LEN(bucket_name)];

  keys        = [[riakpb listKeysInBucket:bucket] autorelease];

  rb_keys     = rb_ary_new2([keys count]);

  [keys enumerateObjectsUsingBlock:^(id key, size_t index, BOOL *stop) {
    rb_ary_store(rb_keys, index, rb_str_new([key cString], [key cStringLength]));
  }];

  return rb_keys;
}

VALUE rb_get_client_id_request(VALUE self) {
  RiakProtobuf   *riakpb  = Get_RiakProtobuf(self);
  OFNumber       *client_id;
  VALUE           rb_client_id;

  client_id     = [[riakpb clientIdRequest] autorelease];
  rb_client_id  = INT2FIX([client_id intValue]); // rb_str_new([client_id cString], [client_id cStringLength]);

  return rb_client_id;
}

VALUE rb_get_server_info_request(VALUE self) {
  RiakProtobuf   *riakpb  = Get_RiakProtobuf(self);
  OFDictionary   *server_info;
  VALUE           rb_server_info;

  server_info     = [[riakpb getServerInfoRequest] autorelease];

  rb_server_info  = rb_hash_new();

  [server_info enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
    rb_hash_aset( rb_server_info,
                  ID2SYM(rb_intern([key cString])),
                  rb_str_new([value cString], [value cStringLength])
                );
  }];

  return rb_server_info;
}







