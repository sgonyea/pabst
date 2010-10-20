
#import <ObjFW/ObjFW.h>
#import "ObjFW+Ruby.h"
#import <stdint.h>
#import "RiakProtobuf.h"
#import "ruby.h"

#define Get_RiakProtobuf(_rpb) ((RiakProtobuf *)DATA_PTR(_rpb))

VALUE rb_ping_request(VALUE);
VALUE rb_get_client_id_request(VALUE);
VALUE rb_set_client_id_request(VALUE, VALUE); // @TODO
VALUE rb_get_server_info_request(VALUE);
VALUE rb_get_key_request(VALUE, VALUE, VALUE);
VALUE rb_put_key_request(VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE, VALUE);
VALUE rb_list_keys_request(VALUE, VALUE);
