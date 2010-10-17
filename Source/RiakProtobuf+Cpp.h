/*
 *  RiakProtobuf+Cpp.h
 *  riak_pb-objc
 *
 *  Created by Scott Gonyea on 10/16/10.
 *
 */

#import "RiakProtobuf.h"




#import <ObjFW/OFDataArray.h>
#import "ruby.h"

/**
 * This header file segments the C++ Protobuf lib-specific stuff, away from the
 *  regular RiakProtobuf header file... which is in use by C/ObjC.
 */
@interface RiakProtobuf (Cpp)

- (OFMutableDictionary *)unpackContent:(RpbContent)pbContent;
- (RpbContent)packContent:(OFDictionary *)pbContent;

@end
