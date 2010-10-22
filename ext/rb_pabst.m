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
  key         = [[riakpb getKey:RString_To_OFString(key_name,     OF_STRING_ENCODING_UTF_8)
                     fromBucket:RString_To_OFString(bucket_name,  OF_STRING_ENCODING_UTF_8)
                         quorum:nil] autorelease];

  vclock      = [key objectForKey:@"vclock"];
  contents    = [key objectForKey:@"content"];

  if (vclock)   rb_vclock   = [vclock toRuby];

  if (contents) {
    if([contents respondsToSelector:@selector(toRubyWithSymbolicKeys)])
      rb_contents = [contents toRubyWithSymbolicKeys];
    else
      rb_contents = [contents toRuby];
  }

  rb_hash_aset( rb_key, ID2SYM(rb_intern("vclock")),    (rb_vclock)   ? rb_vclock
                                                                      : Qnil);
  rb_hash_aset( rb_key, ID2SYM(rb_intern("contents")),  (rb_contents) ? rb_contents
                                                                      : Qnil);
  [pool release];
  return rb_key;
}

// Welcome to MACRO City!
VALUE rb_put_key_request(VALUE self,   VALUE bucket_name,  VALUE key_name,   VALUE rb_content, 
                         VALUE vclock, VALUE rb_quorum,    VALUE rb_commit,  VALUE return_body) {

  Check_Type(bucket_name, T_STRING);
  Check_Type(key_name,    T_STRING);
  Check_Type(rb_content,  T_HASH);

  if(rb_quorum != Qnil) Check_Type(rb_quorum, T_FIXNUM);
  if(rb_commit != Qnil) Check_Type(rb_commit, T_FIXNUM);

  OFAutoreleasePool    *pool        = [[OFAutoreleasePool alloc] init];
  RiakProtobuf         *riakpb      = Get_RiakProtobuf(self);
  VALUE                 rb_key      = rb_hash_new(),
                        rb_vclock   = Qnil,
                        rb_tmp	    = Qnil,
                        rb_return   = Qnil;
  OFDictionary         *key;
  OFString						 *vClock;
  OFMutableDictionary  *content     = [[OFMutableDictionary alloc] init];
  int                   quorum      = NUM2INT(rb_quorum),
                        commit      = NUM2INT(rb_commit);
  BOOL                  returnBody  = YES;

  if(Qfalse == return_body)
    returnBody = NO;

  if(vclock != Qnil) {
    Check_Type(vclock, T_STRING);
    vClock = RString_To_OFString(rb_vclock, OF_STRING_ENCODING_ISO_8859_15);
  } else {
    vClock = nil;
  }

  RHash_To_OFDictionary(rb_content, ID2SYM(rb_intern("value")), rb_tmp,
                        content, @"value", RString_To_OFString(rb_tmp, OF_STRING_ENCODING_UTF_8));

  RHash_To_OFDictionary(rb_content, ID2SYM(rb_intern("content_type")), rb_tmp,
                        content, @"content_type", RString_To_OFString(rb_tmp, OF_STRING_ENCODING_UTF_8));

  RHash_To_OFDictionary(rb_content, ID2SYM(rb_intern("charset")), rb_tmp,
                        content, @"charset", RString_To_OFString(rb_tmp, OF_STRING_ENCODING_UTF_8));

  RHash_To_OFDictionary(rb_content, ID2SYM(rb_intern("content_encoding")), rb_tmp,
                        content, @"content_encoding", RString_To_OFString(rb_tmp, OF_STRING_ENCODING_UTF_8));

  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("links")));

  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_ARRAY);

    OFDataArray  *link = [OFDataArray dataArrayWithItemSize:sizeof(OFDictionary)];
    int 					iter;

    for(iter = 0; iter < RARRAY_LEN(rb_tmp); iter++) {
      VALUE 			rb_link_hash_tmp = rb_ary_entry(rb_tmp, iter);
      VALUE				rb_link_elem_tmp;
      OFString	 *link_bucket, *link_key, *link_tag;
      
      Check_Type(rb_link_hash_tmp, T_HASH);

      rb_link_elem_tmp = rb_hash_aref(rb_link_hash_tmp, ID2SYM(rb_intern("bucket")));

			if(rb_link_elem_tmp != Qnil) {
        Check_Type(rb_link_elem_tmp, T_STRING);
        link_bucket	= RString_To_OFString(rb_link_elem_tmp, OF_STRING_ENCODING_UTF_8);
      } else {
        link_bucket = nil;
      }

      rb_link_elem_tmp = rb_hash_aref(rb_link_hash_tmp, ID2SYM(rb_intern("key")));

			if(rb_link_elem_tmp != Qnil) {
        Check_Type(rb_link_elem_tmp, T_STRING);
        link_key 		= RString_To_OFString(rb_link_elem_tmp, OF_STRING_ENCODING_UTF_8);
      } else
        link_key 		= nil;

      rb_link_elem_tmp = rb_hash_aref(rb_link_hash_tmp, ID2SYM(rb_intern("tag")));

			if(rb_link_elem_tmp != Qnil) {
        Check_Type(rb_link_elem_tmp, T_STRING);
        link_tag		= RString_To_OFString(rb_link_elem_tmp, OF_STRING_ENCODING_UTF_8);
      } else {
        link_tag 		= nil;
      }

      [link addItem:[OFDictionary dictionaryWithKeysAndObjects:
                     @"bucket", link_bucket,
                     @"key",		link_key,
                     @"tag",		link_tag,
                     nil]];
    }

    [content setObject:link forKey:@"links"];
  }

  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("user_meta")));

  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_ARRAY);

    OFDataArray  *uMeta = [OFDataArray dataArrayWithItemSize:sizeof(OFDictionary)];
    int 					iter;

    for(iter = 0; iter < RARRAY_LEN(rb_tmp); iter++) {
      VALUE 			rb_uMeta_hash_tmp = rb_ary_entry(rb_tmp, iter);
      VALUE				rb_uMeta_elem_tmp;
      OFString	 *uMeta_key;
      OFString	 *uMeta_value;

      Check_Type(rb_uMeta_hash_tmp, T_HASH);

      rb_uMeta_elem_tmp = rb_hash_aref(rb_uMeta_hash_tmp, ID2SYM(rb_intern("key")));

			if(rb_uMeta_elem_tmp != Qnil) {
        Check_Type(rb_uMeta_elem_tmp, T_STRING);
        uMeta_key 	= RString_To_OFString(rb_uMeta_elem_tmp, OF_STRING_ENCODING_UTF_8);
      } else {
        uMeta_key 	= nil;
      }

      rb_uMeta_elem_tmp = rb_hash_aref(rb_uMeta_hash_tmp, ID2SYM(rb_intern("value")));

			if(rb_uMeta_elem_tmp != Qnil) {
        Check_Type(rb_uMeta_elem_tmp, T_STRING);
        uMeta_value = RString_To_OFString(rb_uMeta_elem_tmp, OF_STRING_ENCODING_UTF_8);
      } else {
        uMeta_value = nil;
      }

      [uMeta addItem:[OFDictionary dictionaryWithKeysAndObjects:
                       @"key",    uMeta_key,
                       @"value",  uMeta_value,
                       nil]];
    }
    [content setObject:uMeta forKey:@"user_meta"];
  }

  // @TODO: Check the Ruby encoding and set it accordingly
  key = [[riakpb putKey:RString_To_OFString(key_name,     OF_STRING_ENCODING_UTF_8)
               inBucket:RString_To_OFString(bucket_name,  OF_STRING_ENCODING_UTF_8)
                 vClock:vClock
                content:content
                 quorum:quorum
                 commit:commit
             returnBody:returnBody] autorelease];

  if(returnBody)
    rb_return = [key toRubyWithSymbolicKeys];
  else
    rb_return = rb_content;

  [pool release];
  return rb_return;
}

VALUE rb_del_key_request(VALUE self, VALUE bucket_name, VALUE key_name, VALUE rw) {
  Check_Type(bucket_name, T_STRING);
  Check_Type(key_name,    T_STRING);

  if(rw != Qnil)
    Check_Type(rw, T_FIXNUM);

  OFAutoreleasePool  *pool  = [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb  = Get_RiakProtobuf(self);

  if([riakpb deleteKey:RString_To_OFString(key_name,     OF_STRING_ENCODING_UTF_8)
            fromBucket:RString_To_OFString(bucket_name,  OF_STRING_ENCODING_UTF_8)
              replicas:NUM2INT(rw)]
     ) {
    [pool release];
    return Qtrue;
  } else {
    [pool release];
    return Qfalse;
  }
}

VALUE rb_list_keys_request(VALUE self, VALUE bucket_name) {
  OFAutoreleasePool  *pool    = [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb  = Get_RiakProtobuf(self);
  OFDataArray        *keys;
  VALUE               rb_keys;

  // @TODO: Ensure that bucket name is a String, or call :to_s. Raise intelligent exception if that fails
  // @TODO: Figure out how to get the encoding of the String. Assumption is a UTF-8 encoding, for now.
  keys        = [[riakpb listKeysInBucket:RString_To_OFString(bucket_name,  OF_STRING_ENCODING_UTF_8)]
                 autorelease];

  rb_keys     = [keys toRuby];

  [pool release];
  return rb_keys;
}

