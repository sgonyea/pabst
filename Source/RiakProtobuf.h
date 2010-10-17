//
//  RiakProtobuf.h
//  riak_pb-objc
//
//  Created by Scott Gonyea on 9/1/10.
//  Copyright (c) 2010 Inherently Lame Inc. All rights reserved.
//
#import <ObjFW/ObjFW.h>
#import "ObjFW+Ruby.h"
#import "MessageCodes.h"

@interface RiakProtobuf : OFObject {
  OFTCPSocket  *socket;
  OFNumber     *clientId;
@private
}
- (id)init;
- (id)initWithService:(OFString *)port onNode:(OFString *)node;
- (void)connectToService:(OFString *)port onNode:(OFString *)node;
- (void)sendMessageWithLength:(OFNumber *)length message:(char *)message messageCode:(OFNumber *)code;
- (void)dealloc;

//- (OFMutableDictionary *)unpackContent:(RpbContent *)content;
//- (RpbContent *)packContent:(OFMutableDictionary *)content;

- (OFDictionary *)errorResponse:(char *)response;

- (BOOL)pingRequest;  // Message Code Only
- (BOOL)pingGetResponse; // Message Code Only

- (OFNumber *)clientIdRequest;  // Message Code Only
- (OFNumber *)clientIdGetResponse;

- (BOOL)setClientId:(OFString *)clientId;
- (BOOL)setClientIdResponse; // Message Code Only

- (OFDictionary *)getServerInfoRequest; // Message Code Only
- (OFDictionary *)getServerInfoResponse;

- (OFDictionary *)getFromBucket:(OFString *)bucket atKey:(OFString *)key quorum:(OFNumber *)quorum;
- (OFDictionary *)getKeyResponse;

- (OFDictionary *)putInBucket:(OFString *)bucket withKey:(OFString *)key content:(OFDictionary *)content withBody:(BOOL)body quorum:(OFNumber *)quorum commit:(OFNumber *)commit;
- (OFDictionary *)putKeyResponse;

- (BOOL)deleteKey:(OFString *)key fromBucket:(OFString *)bucket replicas:(OFNumber *)replicas;
- (BOOL)deleteKeyResponse; // Message Code Only

- (OFArray *)listBucketsRequest; // Message Code Only
- (OFArray *)listBucketsResponse;

- (OFMutableArray *)listKeysInBucket:(OFString *)bucket;
- (OFMutableArray *)listKeysGetResponse;

- (OFDictionary *)getBucket:(OFString *)bucket;
- (OFDictionary *)getBucketResponse;

- (BOOL)setPropInBucket:(OFString *)bucket nVal:(OFNumber *)nVal isMult:(BOOL)isMult;
- (BOOL)setBucketResponse; // Message Code Only

- (OFDictionary *)mapReduceRequest:(char *)request contentType:(OFString *)contentType;
- (OFDictionary *)mapReduceResponse;

@end
