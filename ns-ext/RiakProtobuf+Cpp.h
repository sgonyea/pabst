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

/**
 *  Receive a single response
 */
- (void)sendMessage:(google::protobuf::Message *)protobuf
           withCode:(uint8_t)code;

- (int8_t)receiveResponseWithCode:(int8_t)expectedCode
                       inProtobuf:(google::protobuf::Message *)protobuf;

- (OFDictionary *)unpackContent:(RpbContent)pbContent;

- (void)packContent:(RpbContent *)pbContent
     fromDictionary:(OFDictionary *)content;

- (OFDataArray *)unpackLinksFromContent:(RpbContent)pbContent;

- (void)packLinks:(OFDataArray *)links
        inContent:(RpbContent *)content;

- (OFDataArray *)unpackUserMetaFromContent:(RpbContent)pbContent;

- (void)packUserMeta:(OFDataArray *)userMeta
           inContent:(RpbContent *)content;

@end
