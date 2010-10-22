
#import <ObjFW/ObjFW.h>
#import "ObjFW+Ruby.h"
#import <stdint.h>
#import "RiakProtobuf.h"
#import "ruby.h"

#define Get_RiakProtobuf(_rpb) ((RiakProtobuf *)DATA_PTR(_rpb))
#define RHash_RString_To_Dictionary_StrObj(	_rb_hash_, 	_rb_key_, _rb_val_, 	\
																						_dic_, 			_key_, 		_enc_) ({		\
     																																					\
_rb_val_ = rb_hash_aref(_rb_hash_, _rb_key_);																	\
     																																					\
if(_rb_val_ != Qnil){																													\
  Check_Type(_rb_val_, T_STRING);																							\
  [_dic_ setObject:[OFString stringWithCString:RSTRING_PTR(_rb_val_)					\
																				encoding:_enc_												\
                                          length:RSTRING_LEN(_rb_val_)]				\
            forKey:_key_];																										\
}})

VALUE rb_ping_request(VALUE);
VALUE rb_get_client_id_request(VALUE);
VALUE rb_set_client_id_request(VALUE, VALUE); // @TODO
VALUE rb_get_server_info_request(VALUE);
VALUE rb_get_key_request(VALUE, VALUE, VALUE);
VALUE rb_put_key_request(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE);
VALUE rb_list_keys_request(VALUE, VALUE);
