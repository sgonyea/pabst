//
//  rb_riakpb.h
//  riak_pb-objc
//
//  Created by Scott Gonyea on 9/1/10.
//
#import <Foundation/Foundation.h>
#import "Foundation+RubyValue.h"
#import "RiakProtobuf.h"
#import "rb_pabst.h"
#import "ruby.h"

void  Init_Riakpb();
VALUE pabst_allocate(VALUE);
VALUE pabst_initialize(VALUE);
void  pabst_mark(RiakProtobuf *);
void  pabst_free(RiakProtobuf *);

