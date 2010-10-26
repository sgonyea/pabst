
#import <ObjFW/ObjFW.h>
#import "ObjFW+RubyValue.h"
#import <stdint.h>
#import "RiakProtobuf.h"
#import "ruby.h"

#define Get_RiakProtobuf(_rpb) ((RiakProtobuf *)DATA_PTR(_rpb))

#define RString_To_OFString(rb_string, of_encoding) (    \
  [OFString stringWithCString:RSTRING_PTR(rb_string)     \
                     encoding:of_encoding                \
                       length:RSTRING_LEN(rb_string)]    \
)

#define RHash_To_OFDictionary(  rb_hash,    rb_key, rb_val,         \
                                dictionary, of_key, of_value) ({    \
  rb_val = rb_hash_aref(rb_hash, rb_key);                           \
                                                                    \
  if(rb_val != Qnil) {                                              \
    Check_Type(rb_val, T_STRING);                                   \
    [dictionary setObject:of_value                                  \
                   forKey:of_key];                                  \
  }})
#define RHash_RString_To_OFString(rb_hash, rb_key)(                  \
RString_To_UTF8OFString(rb_hash_aref(  rb_hash,                       \
                                      ID2SYM(rb_intern(rb_key))),    \
                        OF_STRING_ENCODING_UTF_8)                    \
  )


VALUE rb_ping_request(VALUE);
VALUE rb_get_client_id_request(VALUE);
VALUE rb_set_client_id_request(VALUE, VALUE); // @TODO
VALUE rb_get_server_info_request(VALUE);
VALUE rb_get_key_request(VALUE, VALUE, VALUE);
VALUE rb_put_key_request(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE);
VALUE rb_del_key_request(VALUE, VALUE, VALUE, VALUE);
VALUE rb_list_buckets_request(VALUE);
VALUE rb_list_keys_request(VALUE, VALUE);
VALUE rb_get_bucket_request(VALUE, VALUE);
VALUE rb_set_bucket_request(VALUE, VALUE, VALUE, VALUE);
VALUE rb_map_reduce_request(VALUE, VALUE, VALUE);
