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

VALUE rb_put_key_request(VALUE self,   VALUE bucket_name,  VALUE key_name,   VALUE rb_content, 
                         VALUE vclock, VALUE rb_quorum,    VALUE rb_commit,  VALUE return_body) {

  Check_Type(bucket_name, T_STRING);
  Check_Type(key_name,    T_STRING);
  Check_Type(rb_content,  T_HASH);

  
  puts("tst01\n");
  if(vclock != Qnil)
    Check_Type(vclock, T_STRING);
  if(rb_quorum != Qnil)
    Check_Type(rb_quorum, T_FIXNUM);
  if(rb_commit != Qnil)
    Check_Type(rb_commit, T_FIXNUM);
  puts("tst02\n");
  OFAutoreleasePool    *pool        = [[OFAutoreleasePool alloc] init];
  RiakProtobuf         *riakpb      = Get_RiakProtobuf(self);
  VALUE                 rb_key      = rb_hash_new(),
                        rb_vclock   = Qnil,
                        rb_tmp	    = Qnil,
                        rb_return   = Qnil;
  OFDictionary         *key         = nil;
  OFMutableDictionary  *content     = [[OFMutableDictionary alloc] init];
  int                   quorum      = NUM2INT(rb_quorum),
                        commit      = NUM2INT(rb_commit);
  BOOL                  returnBody  = YES;
  puts("tst03\n");
  if(Qfalse == return_body)
    returnBody = NO;
puts("tst04");
  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("value")));
  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_STRING);
    [content setObject:[OFString stringWithCString:RSTRING_PTR(rb_tmp)
                                            length:RSTRING_LEN(rb_tmp)]
                forKey:@"value"];
  }
puts("tst05\n");
  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("content_type")));
  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_STRING);
    [content setObject:[OFString stringWithCString:RSTRING_PTR(rb_tmp)
                                            length:RSTRING_LEN(rb_tmp)]
                forKey:@"content_type"];
  }
puts("tst06\n");
  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("charset")));
  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_STRING);
    [content setObject:[OFString stringWithCString:RSTRING_PTR(rb_tmp)
                                            length:RSTRING_LEN(rb_tmp)]
                forKey:@"charset"];
  }
puts("tst07\n");
  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("content_encoding")));
  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_STRING);
    [content setObject:[OFString stringWithCString:RSTRING_PTR(rb_tmp)
                                            length:RSTRING_LEN(rb_tmp)]
                forKey:@"content_encoding"];
  }
puts("tst08\n");
  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("links")));

  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_ARRAY);

    OFDataArray  *link = [OFDataArray dataArrayWithItemSize:sizeof(OFDictionary)];
    int 					iter;

    for(iter = 0; iter < RARRAY_LEN(rb_tmp); iter++) {
      VALUE 			rb_link_hash_tmp = rb_ary_entry(rb_tmp, iter);
      VALUE				rb_link_elem_tmp;
      OFString	 *link_bucket;
      OFString	 *link_key;
      OFString	 *link_tag;

      Check_Type(rb_link_hash_tmp, T_HASH);

      rb_link_elem_tmp = rb_hash_aref(rb_link_hash_tmp, ID2SYM(rb_intern("bucket")));
      
			if(rb_link_elem_tmp != Qnil) {
        Check_Type(rb_link_elem_tmp, T_STRING);
        link_bucket	= [OFString stringWithCString:RSTRING_PTR(rb_link_elem_tmp)
                                           length:RSTRING_LEN(rb_link_elem_tmp)];
      } else {
        link_bucket = nil;
      }

      rb_link_elem_tmp = rb_hash_aref(rb_link_hash_tmp, ID2SYM(rb_intern("key")));

			if(rb_link_elem_tmp != Qnil) {
        Check_Type(rb_link_elem_tmp, T_STRING);
        link_key 		= [OFString stringWithCString:RSTRING_PTR(rb_link_elem_tmp)
                    	                     length:RSTRING_LEN(rb_link_elem_tmp)];
      } else {
        link_key 		= nil;
      }

      rb_link_elem_tmp = rb_hash_aref(rb_link_hash_tmp, ID2SYM(rb_intern("tag")));
      
			if(rb_link_elem_tmp != Qnil) {
        Check_Type(rb_link_elem_tmp, T_STRING);
        link_tag		= [OFString stringWithCString:RSTRING_PTR(rb_link_elem_tmp)
                                           length:RSTRING_LEN(rb_link_elem_tmp)];
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
puts("tst09\n");
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
        uMeta_key 	= [OFString stringWithCString:RSTRING_PTR(rb_uMeta_elem_tmp)
                                           length:RSTRING_LEN(rb_uMeta_elem_tmp)];
      } else {
        uMeta_key 	= nil;
      }

      rb_uMeta_elem_tmp = rb_hash_aref(rb_uMeta_hash_tmp, ID2SYM(rb_intern("value")));

			if(rb_uMeta_elem_tmp != Qnil) {
        Check_Type(rb_uMeta_elem_tmp, T_STRING);
        uMeta_value = [OFString stringWithCString:RSTRING_PTR(rb_uMeta_elem_tmp)
                                           length:RSTRING_LEN(rb_uMeta_elem_tmp)];
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
puts("tst10\n");
  // @TODO: Check the Ruby encoding and set it accordingly
  key = [riakpb  putKey:[OFString stringWithCString:RSTRING_PTR(key_name)
                                             length:RSTRING_LEN(key_name)]
               inBucket:[OFString stringWithCString:RSTRING_PTR(bucket_name)
                                             length:RSTRING_LEN(bucket_name)]
                 vClock:((rb_vclock == Qnil)  ?  nil
                                              : [OFString stringWithCString:RSTRING_PTR(rb_vclock)
                                                                     length:RSTRING_LEN(rb_vclock)])
                content:content
                 quorum:quorum
                 commit:commit
             returnBody:returnBody];
puts("tst11\n");
  if(returnBody)
    rb_return = [key toRuby];
  else
    rb_return = rb_content;

  puts("tst14\n");
  [pool release];
  return rb_return;
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





