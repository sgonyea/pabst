//
//  rb_riakpb.m
//  riak_pb-objc
//
//  Created by Scott Gonyea on 9/1/10.
//
#import "rb_riakpb.h"

VALUE   rb_mRiakpb  = Qnil;
VALUE   rb_cPabst   = Qnil;

void Init_Riakpb() {
  rb_mRiakpb  = rb_define_module("Riakpb");
  rb_cPabst   = rb_define_class_under(rb_mRiakpb, "Pabst", rb_cObject);

  rb_define_alloc_func(rb_cPabst, pabst_allocate);

  rb_define_method(rb_cPabst, "initialize",           pabst_initialize,             0);
//  rb_define_method(rb_cPabst, "ping?",                rb_ping_request,              0);
  rb_define_method(rb_cPabst, "get_client_id",        rb_get_client_id_request,     0);
  rb_define_method(rb_cPabst, "server_info",          rb_get_server_info_request,   0);
  rb_define_method(rb_cPabst, "get_key",              rb_get_key_request,           2);
  rb_define_method(rb_cPabst, "put_key",              rb_put_key_request,           7);
  rb_define_method(rb_cPabst, "list_keys",            rb_list_keys_request,         1);
}

VALUE pabst_allocate(VALUE klass) {
  RiakProtobuf *riakpb;

  riakpb  = [RiakProtobuf alloc];

  return Data_Wrap_Struct(klass, pabst_mark, pabst_free, riakpb);
}

VALUE pabst_initialize(VALUE self) {
  RiakProtobuf *riakpb = Get_RiakProtobuf(self);

  [riakpb initWithService:@"8087" onNode:@"127.0.0.1"];

  return self;
}

void pabst_mark(RiakProtobuf *self) {
  /* Nothing to do, right now */
}

void pabst_free(RiakProtobuf *self) {
  [self release];
}


