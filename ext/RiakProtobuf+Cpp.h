/*
 *  RiakProtobuf+Cpp.h
 *  riak_pb-objc
 *
 *  Created by Scott Gonyea on 10/16/10.
 *
 */

#import "RiakProtobuf.h"
#import "riakclient.pb.h"

/**
 * This header file segments the C++ Protobuf lib-specific stuff, away from the
 *  regular RiakProtobuf header file... which is in use by C/ObjC.
 */
@interface RiakProtobuf (Cpp)

- (OFMutableDictionary *)unpackContent:(RpbContent)pbContent;
- (void)packContent:(RpbContent)pbContent fromDictionary:(OFDictionary *)content;

- (OFDataArray *)unpackLinksFromContent:(RpbContent)pbContent;
- (void)packLinks:(OFDataArray *)pbLink fromData:(OFDataArray *)links;

- (OFDataArray *)unpackUserMetaFromContent:(RpbContent)pbContent;
- (void)packUserMeta:(OFDataArray *)pbMeta fromData:(OFDataArray *)metas;

@end
