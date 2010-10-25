
#import "rb_pabst.h"

VALUE rb_ping_request(VALUE self) {
  RiakProtobuf   *riakpb  = Get_RiakProtobuf(self);

  @try {
    if([riakpb pingRiak])
      return Qtrue;
  }
  @catch (OFException *e) {
    rb_raise(rb_eRuntimeError, "Caught: %s", [[e string] cString]);
    [e dealloc];
  }

  return Qfalse;
}

VALUE rb_get_client_id_request(VALUE self) {
  OFAutoreleasePool  *pool      = [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb  	= Get_RiakProtobuf(self);
  OFNumber           *clientId	= nil;
  VALUE               rb_client_id;

  clientId      = [riakpb getClientId];
  rb_client_id  = [clientId toRuby];

	[pool drain];
  return rb_client_id;
}

VALUE rb_get_server_info_request(VALUE self) {
  OFAutoreleasePool  *pool    = [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb  = Get_RiakProtobuf(self);
  OFDictionary       *serverInfo;
  VALUE               rb_server_info;

  serverInfo      = [riakpb getServerInfo];
  rb_server_info  = [serverInfo toRuby];

	[pool drain];
  return rb_server_info;
}

VALUE rb_get_key_request(VALUE self, VALUE bucket_name, VALUE key_name) {
  OFAutoreleasePool  *pool        = [[OFAutoreleasePool alloc] init];

  RiakProtobuf       *riakpb      = Get_RiakProtobuf(self);
  VALUE               rb_key      = rb_hash_new(),
                      rb_vclock   = Qnil,
                      rb_contents = Qnil;
  OFDictionary       *key					= nil;
  OFString           *vclock			= nil;
  OFDataArray        *contents		= nil;

  // @TODO: Allow the quorum to be set
  key         = [riakpb getKey:RString_To_OFString(key_name,     OF_STRING_ENCODING_UTF_8)
                    fromBucket:RString_To_OFString(bucket_name,  OF_STRING_ENCODING_UTF_8)
                        quorum:0]; // @TODO: Don't hardcode the quorum, yo

  vclock      = [key objectForKey:@"vclock"];
  contents    = [key objectForKey:@"content"];

  if (vclock)
    rb_vclock = [vclock toRuby];

  if (contents) {
    if([contents respondsToSelector:@selector(toRubyWithSymbolicKeys)])
      rb_contents = [contents toRubyWithSymbolicKeys];
    else if([contents respondsToSelector:@selector(toRuby)])
      rb_contents = [contents toRuby];
    else
      rb_contents = Qnil;
  }

  rb_hash_aset( rb_key, ID2SYM(rb_intern("vclock")),    (rb_vclock)   ? rb_vclock
                                                                      : Qnil);
  rb_hash_aset( rb_key, ID2SYM(rb_intern("contents")),  (rb_contents) ? rb_contents
                                                                      : Qnil);

  [pool drain];
  return rb_key;
}

// Welcome to MACRO City!
VALUE rb_put_key_request(VALUE self,   VALUE bucket_name,  VALUE key_name,   VALUE rb_content, 
                         VALUE vclock, VALUE rb_quorum,    VALUE rb_commit,  VALUE return_body) {

  Check_Type(bucket_name, T_STRING);
  Check_Type(key_name,    T_STRING);
  Check_Type(rb_content,  T_HASH);

  OFAutoreleasePool    *pool        		= [[OFAutoreleasePool alloc] init];
  RiakProtobuf         *riakpb      		= Get_RiakProtobuf(self);
  VALUE                 rb_vclock   		= Qnil,
                        rb_tmp	    		= Qnil,
                        rb_return   		= Qnil;
  OFDictionary         *key;
  OFDataArray					 *links						= nil,
                       *metas						= nil;
  OFString						 *vClock					= nil,
                       *contentValue		= nil,
                       *contentType			= nil,
                       *contentCharset	= nil,
                       *contentEncoding	= nil;
  int                   quorum					= 0,
                        commit					= 0;
  BOOL                  returnBody  		= YES;

  if(rb_quorum 		!= Qnil) 		quorum      = FIX2INT(rb_quorum);
  if(rb_commit 		!= Qnil) 		commit      = FIX2INT(rb_commit);
  if(return_body 	== Qfalse)	returnBody 	= NO;

  if(vclock != Qnil) {
    Check_Type(vclock, T_STRING);
    vClock = RString_To_OFString(rb_vclock, OF_STRING_ENCODING_ISO_8859_15);
  }

  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("value")));
  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_STRING);
    contentValue = RString_To_OFString(rb_tmp, OF_STRING_ENCODING_UTF_8);
  }

  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("content_type")));
  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_STRING);
    contentType = RString_To_OFString(rb_tmp, OF_STRING_ENCODING_UTF_8);
  }

  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("charset")));
  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_STRING);
    contentCharset = RString_To_OFString(rb_tmp, OF_STRING_ENCODING_UTF_8);
  }

  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("content_encoding")));
  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_STRING);
    contentEncoding = RString_To_OFString(rb_tmp, OF_STRING_ENCODING_UTF_8);
  }

  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("links")));
  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_ARRAY);

    int iter;

    links = [OFDataArray dataArrayWithItemSize:sizeof(OFDictionary)];

    for(iter = 0; iter < RARRAY_LEN(rb_tmp); iter++) {

      VALUE 			rb_link_hash_tmp 	= rb_ary_entry(rb_tmp, iter);
      VALUE				rb_link_elem_tmp;
      OFString	 *link_bucket				= nil,
      					 *link_key					= nil,
      					 *link_tag					= nil;
      
      Check_Type(rb_link_hash_tmp, T_HASH);

      rb_link_elem_tmp = rb_hash_aref(rb_link_hash_tmp, ID2SYM(rb_intern("bucket")));

			if(rb_link_elem_tmp != Qnil) {
        Check_Type(rb_link_elem_tmp, T_STRING);
        link_bucket	= RString_To_OFString(rb_link_elem_tmp, OF_STRING_ENCODING_UTF_8);
      }

      rb_link_elem_tmp = rb_hash_aref(rb_link_hash_tmp, ID2SYM(rb_intern("key")));

			if(rb_link_elem_tmp != Qnil) {
        Check_Type(rb_link_elem_tmp, T_STRING);
        link_key 		= RString_To_OFString(rb_link_elem_tmp, OF_STRING_ENCODING_UTF_8);
      }

      rb_link_elem_tmp = rb_hash_aref(rb_link_hash_tmp, ID2SYM(rb_intern("tag")));

			if(rb_link_elem_tmp != Qnil) {
        Check_Type(rb_link_elem_tmp, T_STRING);
        link_tag		= RString_To_OFString(rb_link_elem_tmp, OF_STRING_ENCODING_UTF_8);
      }

      [links addItem:[OFDictionary dictionaryWithKeysAndObjects:
                   	  @"bucket", link_bucket,
                   	  @"key",		link_key,
                      @"tag",		link_tag,
                      nil]];
    }
  }

  rb_tmp = rb_hash_aref(rb_content, ID2SYM(rb_intern("user_meta")));

  if(rb_tmp != Qnil) {
    Check_Type(rb_tmp, T_ARRAY);

    int iter;

    metas = [OFDataArray dataArrayWithItemSize:sizeof(OFDictionary)];

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

      [metas addItem:[OFDictionary dictionaryWithKeysAndObjects:
                       @"key",    uMeta_key,
                       @"value",  uMeta_value,
                       nil]];
    }
  }

  // @TODO: Check the Ruby encoding and set it accordingly
  key =  [riakpb putKey:RString_To_OFString(key_name,     OF_STRING_ENCODING_UTF_8)
               inBucket:RString_To_OFString(bucket_name,  OF_STRING_ENCODING_UTF_8)
                 vClock:vClock
                content:[OFDictionary dictionaryWithKeysAndObjects:
                         @"value", 						contentValue,
                         @"content_type", 		contentType,
                         @"charset", 					contentCharset,
                         @"content_encoding", contentEncoding,
                         @"links", 						links,
                         @"user_meta", 				metas,
                         nil]
                 quorum:quorum
                 commit:commit
             returnBody:returnBody];

  if(returnBody)
    rb_return = [key toRubyWithSymbolicKeys];
  else
    rb_return = rb_content;

  [pool drain];
  return rb_return;
}

VALUE rb_del_key_request(VALUE self, VALUE bucket_name, VALUE key_name, VALUE rw) {
  Check_Type(bucket_name, T_STRING);
  Check_Type(key_name,    T_STRING);

  VALUE rb_return;
	int 	replicas;
  
  if(rw != Qnil) 	replicas = FIX2INT(rw);
  else						replicas = 0;

  OFAutoreleasePool  *pool  = [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb  = Get_RiakProtobuf(self);

  if([riakpb deleteKey:RString_To_OFString(key_name,     OF_STRING_ENCODING_UTF_8)
            fromBucket:RString_To_OFString(bucket_name,  OF_STRING_ENCODING_UTF_8)
              replicas:replicas])
  	rb_return	= Qtrue;
  else
    rb_return	= Qfalse;

  [pool drain];
  return rb_return;
}

VALUE rb_list_buckets_request(VALUE self) {
  OFAutoreleasePool  *pool    = [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb  = Get_RiakProtobuf(self);
  VALUE bucketList;

  bucketList	= [[riakpb listBucketsRequest]
                 toRuby];

  [pool drain];
  return bucketList;
}

VALUE rb_list_keys_request(VALUE self, VALUE bucket_name) {
  OFAutoreleasePool  *pool    = [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb  = Get_RiakProtobuf(self);
  OFDataArray        *keys;
  VALUE               rb_keys;

  // @TODO: Ensure that bucket name is a String, or call :to_s. Raise intelligent exception if that fails
  // @TODO: Figure out how to get the encoding of the String. Assumption is a UTF-8 encoding, for now.
  keys        = [riakpb listKeysInBucket:RString_To_OFString(bucket_name,  OF_STRING_ENCODING_UTF_8)];

  rb_keys     = [keys toRuby];

  [pool drain];
  return rb_keys;
}

VALUE rb_get_bucket_request(VALUE self, VALUE bucket_name) {

	Check_Type(bucket_name, T_STRING);

  OFAutoreleasePool  *pool 		= [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb 	= Get_RiakProtobuf(self);

  OFDictionary       *bucketProperties;
  VALUE               rb_bucket_props;

	bucketProperties  = [riakpb getBucket:RString_To_OFString(bucket_name,  OF_STRING_ENCODING_UTF_8)];
  rb_bucket_props   = [bucketProperties toRubyWithSymbolicKeys];

	[pool drain];
  return rb_bucket_props;
}

VALUE rb_set_bucket_request(VALUE self, VALUE bucket_name, VALUE n_val, VALUE allow_mult) {

  Check_Type(bucket_name, T_STRING);

  OFAutoreleasePool  *pool    	= [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb  	= Get_RiakProtobuf(self);
  VALUE               rb_did_set;
	uint32_t						nVal			= 0;
  BOOL								allowMult	=	NO;

  if(n_val 			!= Qnil)	nVal 			= FIX2UINT(n_val);
  if(allow_mult == Qtrue)	allowMult = YES;

	if([riakpb setForBucket:RString_To_OFString(bucket_name,  OF_STRING_ENCODING_UTF_8)
                     nVal:nVal
                allowMult:allowMult])
    rb_did_set = Qtrue;
  else
    rb_did_set = Qfalse;

  [pool drain];
  return rb_did_set;
}

VALUE rb_map_reduce_request(VALUE self, VALUE rb_request, VALUE rb_content_type) {
  Check_Type(rb_request, T_STRING);
  Check_Type(rb_content_type, T_STRING);

  OFAutoreleasePool  *pool    	= [[OFAutoreleasePool alloc] init];
  RiakProtobuf       *riakpb  	= Get_RiakProtobuf(self);
  VALUE               rb_mapred = rb_hash_new();

  rb_mapred = [[riakpb mapReduceRequest:RString_To_OFString(rb_request,       OF_STRING_ENCODING_UTF_8)
                          ofContentType:RString_To_OFString(rb_content_type,  OF_STRING_ENCODING_UTF_8)]
               toRuby];

  [pool drain];
  return rb_mapred;
}
