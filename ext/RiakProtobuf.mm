//
//  RiakProtobuf.m
//  riak_pb-objc
//
//  Created by Scott Gonyea on 9/1/10.
//

extern "C" {
#   import "RiakProtobuf.h"
}
#import "RiakProtobuf+Cpp.h"

@implementation RiakProtobuf

- (id)init {
  self    = [super init];
  socket  = [OFTCPSocket socket];

  return self;
}

- (id)initWithService:(OFString *)port onNode:(OFString *)node {
  self    = [super init];
  socket  = [OFTCPSocket socket];

  [self connectToService:port onNode:node];

  return self;
}

- (void)connectToService:(OFString *)port onNode:(OFString *)node {
  [socket connectToService:port onNode:node];
  [socket setKeepAlivesEnabled:YES];
}

- (void)sendEmptyMessageWithCode:(OFNumber *)msgCode {
  [socket bufferWrites];

  [socket writeBigEndianInt32:[[OFNumber numberWithUInt32:MSG_CODE_SIZE] uInt32Value]];
  [socket writeInt8:[msgCode uInt8Value]];

  [socket flushWriteBuffer];
}

- (void)sendMessageWithLength:(OFNumber *)msgLength message:(char *)message messageCode:(OFNumber *)msgCode {
  [socket bufferWrites];

  [socket writeBigEndianInt32:[[msgLength numberByIncreasing] uInt32Value]];
  [socket writeInt8:[msgCode uInt8Value]];
  [socket writeNBytes:[msgLength uInt32Value] fromBuffer:message];

  [socket flushWriteBuffer];
}
/*
- (void)receiveResponses {
  size_t    msgLength;
  uint8_t   msgCode;
  char     *message;

  msgLength = [[OFNumber numberWithUInt32:[socket readBigEndianInt32]]
               numberByDecreasing];

  code      = [OFNumber numberWithUInt8:[socket readInt8]];

  if([msgLength uInt32Value] > 0) {
    message   = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]];
    [socket readNBytes:[msgLength uInt32Value] intoBuffer:message];
  }
}
*/
- (void)dealloc {
  // Clean-up code here.
  [socket release];
  google::protobuf::ShutdownProtobufLibrary();
  [super dealloc];
}

- (BOOL)pingRequest {
  [self sendEmptyMessageWithCode:[OFNumber numberWithUInt8:MC_PING_REQUEST]];
  return [self pingGetResponse];
}

- (BOOL)pingGetResponse {
  OFNumber *msgLength;
  OFNumber *code;
  char     *message;

  // @TODO: Proper response receiving
  receiveResponse(msgLength, code, message);

  return YES;
}

- (OFNumber *)getClientId {
  [self sendEmptyMessageWithCode:[OFNumber numberWithUInt8:MC_GET_CLIENT_ID_REQUEST]];

  OFNumber *newClientId = [self clientIdGetResponse];

  clientId = [newClientId copy];

  return newClientId;
}

- (OFNumber *)clientIdGetResponse {
  RpbGetClientIdResp pbMsg;
  OFNumber *msgLength;
  OFNumber *code;
  char     *message;

  // @TODO: Proper response receiving
  receiveResponse(msgLength, code, message);

  pbMsg.ParseFromArray(message, [msgLength uInt32Value]);

  return [[OFNumber numberWithInt:*(int *)pbMsg.client_id().c_str()] retain];
}

// @TODO: Rest of Set Client ID
- (BOOL)setClientId {
  RpbSetClientIdReq protobuf;
  
  if (!clientId) {
    [self getClientId];
  }
  protobuf.set_client_id((void *)[clientId uInt32Value], sizeof(uint32_t));
  // @TODO: Set the client ID
  return YES;
}

- (OFDictionary *)getServerInfoRequest {
  [self sendEmptyMessageWithCode:[OFNumber numberWithUInt8:MC_GET_SERVER_INFO_REQUEST]];
  return [self getServerInfoResponse];
}

- (OFDictionary *)getServerInfoResponse {
  RpbGetServerInfoResp pbMsg;
  OFNumber *msgLength;
  OFNumber *code;
  char     *message;

  // @TODO: Proper response receiving
  receiveResponse(msgLength, code, message);

  pbMsg.ParseFromArray(message, [msgLength uInt32Value]);

  return [[OFDictionary dictionaryWithKeysAndObjects:
                @"node",    [OFString stringWithCString:pbMsg.node().c_str()
                                                 length:pbMsg.node().length()],
                @"version", [OFString stringWithCString:pbMsg.server_version().c_str()
                                                 length:pbMsg.server_version().length()],
                nil] retain];
}

- (OFDictionary *)getKey:(OFString *)key fromBucket:(OFString *)bucket quorum:(OFNumber *)quorum {
  RpbGetReq   pbMsg;
  char       *message;
  OFNumber   *msgLength;
  OFNumber   *msgCode;

  pbMsg.set_bucket([bucket cString]);
  pbMsg.set_key([key cString]);

  if(quorum) {
    pbMsg.set_r([quorum uInt32Value]);
  }

  msgCode   = [OFNumber numberWithUInt8:MC_GET_REQUEST];
  msgLength = [OFNumber numberWithUInt32:pbMsg.ByteSize()];
  message   = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]];

  pbMsg.SerializeToArray(message, [msgLength uInt32Value]);

  [self sendMessageWithLength:msgLength message:message messageCode:msgCode];
  return [self getKeyResponse];
}

- (OFDictionary *)getKeyResponse {
  RpbGetResp      pbMsg;
  OFMutableArray *contentsArray;
  OFNumber       *msgLength;
  OFNumber       *code;
  char           *message;
  int             iter;

  // @TODO: Proper response receiving
  receiveResponse(msgLength, code, message);

  pbMsg.ParseFromArray(message, [msgLength uInt32Value]);

  contentsArray = [OFMutableArray array];

  for(iter = 0; iter < pbMsg.content_size(); iter++) {
    [contentsArray addObject:[self unpackContent:pbMsg.content(iter)]];
  }

  return [[OFDictionary dictionaryWithKeysAndObjects:
           @"content", contentsArray,
           @"vclock",  [OFString stringWithCString:pbMsg.vclock().c_str()
                                          encoding:OF_STRING_ENCODING_ISO_8859_15
                                            length:pbMsg.vclock().length()],
           nil] retain];
}

- (OFDictionary *)putKey:(OFString *)key inBucket:(OFString *)bucket vClock:(OFString *)vClock content:(OFDictionary *)content quorum:(uint32_t)quorum commit:(uint32_t)commit returnBody:(BOOL)returnBody {
  RpbPutReq   pbMsg;
  RpbContent *pbContent = pbMsg.mutable_content();
  char       *message;
  OFNumber   *msgLength;
  OFNumber   *msgCode;

  pbMsg.set_bucket([bucket cString]);
  pbMsg.set_key([key cString]);
  if(vClock)
    pbMsg.set_vclock([vClock cString]);
  pbMsg.set_w(quorum);
  pbMsg.set_dw(commit);
  pbMsg.set_return_body(returnBody);

  [self packContent:pbContent fromDictionary:content];

  msgCode   = [OFNumber numberWithUInt8:MC_PUT_REQUEST];
  msgLength = [OFNumber numberWithUInt32:pbMsg.ByteSize()];
  message   = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]];

  pbMsg.SerializeToArray(message, [msgLength uInt32Value]);

  [self sendMessageWithLength:msgLength message:message messageCode:msgCode];

  if(returnBody)
    return [self putResponseAndGetBody];
  else
    return [self putResponse];
}

- (OFDictionary *)putResponse {
  RpbPutResp        pbMsg;
  OFMutableArray   *contentsArray;
  OFNumber         *msgLength;
  OFNumber         *code;
  char             *message;
  int               iter;

  // @TODO: Proper response receiving
  // @TODO2: ie, raise exception on error response
  receiveResponse(msgLength, code, message);

  if([code int8Value] == (uint8_t)MC_PUT_RESPONSE)
    return [[OFDictionary dictionaryWithKeysAndObjects:
             @"successful", @"YES",  nil] retain];
  else
    return [[OFDictionary dictionaryWithKeysAndObjects:
             @"successful", @"NO",   nil] retain];
}

- (OFDictionary *)putResponseAndGetBody {
  RpbPutResp      pbMsg;
  OFDataArray 	 *contentsArray;
  OFNumber       *msgLength;
  OFNumber       *code;
  char           *message;
  int             iter;

  // @TODO: Proper response receiving
  receiveResponse(msgLength, code, message);
  pbMsg.ParseFromArray(message, [msgLength uInt32Value]);
  contentsArray = [[OFDataArray dataArrayWithItemSize:sizeof(OFDictionary)] retain];

  for(iter = 0; iter < pbMsg.content_size(); iter++) {
    [contentsArray addItem:[self unpackContent:pbMsg.content(iter)]];
  }

  return [[OFDictionary dictionaryWithKeysAndObjects:
           @"content",    contentsArray,
           @"vclock",     [OFString stringWithCString:pbMsg.vclock().c_str()
                                             encoding:OF_STRING_ENCODING_ISO_8859_15
                                               length:pbMsg.vclock().length()],
           @"successful", @"YES",
           nil] retain];
}

- (BOOL)deleteKey:(OFString *)key fromBucket:(OFString *)bucket withRW:(int)rw {
  RpbDelReq   pbMsg;
  char       *message;
  OFNumber   *msgLength;
  OFNumber   *msgCode;

  pbMsg.set_bucket([bucket cString]);
  pbMsg.set_key([key cString]);

  if(rw)
    pbMsg.set_rw(rw);

  msgCode   = [OFNumber numberWithUInt8:MC_DEL_REQUEST];
  msgLength = [OFNumber numberWithUInt32:pbMsg.ByteSize()];
  message   = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]];

  pbMsg.SerializeToArray(message, [msgLength uInt32Value]);

  [self sendMessageWithLength:msgLength message:message messageCode:msgCode];
  return [self deleteKeyResponse];
}

- (BOOL)deleteKeyResponse {
  OFNumber *msgLength;
  OFNumber *code;
  char     *message;
  
  // @TODO: Proper response receiving
  receiveResponse(msgLength, code, message);
  return YES;
}

- (OFDataArray *)listBucketsRequest {
  [self sendEmptyMessageWithCode:[OFNumber numberWithUInt8:MC_LIST_BUCKETS_REQUEST]];
  return [self listBucketsResponse];
}
- (OFDataArray *)listBucketsResponse {
  RpbListBucketsResp  pbMsg;
  OFNumber           *msgLength;
  OFNumber           *code;
  char               *message;
  int                 iter;
  OFDataArray    *bucketList = [[OFDataArray dataArrayWithItemSize:sizeof(OFString)] retain];

  receiveResponse(msgLength, code, message);
  pbMsg.ParseFromArray(message, [msgLength uInt32Value]);

  for(iter = 0; iter < pbMsg.buckets_size(); iter++) {
    [bucketList addItem:[[OFString stringWithCString:pbMsg.buckets(iter).c_str()
                                              length:pbMsg.buckets(iter).length()] retain]];
  }

  return bucketList;
}


// @TODO: Create an Ostream C++ class and Serialize directly onto the socket buffer.
// @TODO: Delete pbMsg to clean up memory used.
- (OFMutableArray *)listKeysInBucket:(OFString *)bucket {
  RpbListKeysReq  pbMsg;
  char           *message;
  OFNumber       *msgLength;
  OFNumber       *msgCode;

  pbMsg.set_bucket([bucket cString]);

  msgCode   = [OFNumber numberWithUInt8:MC_LIST_KEYS_REQUEST];
  msgLength = [OFNumber numberWithUInt32:pbMsg.ByteSize()];
  message   = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]];

  pbMsg.SerializeToArray(message, [msgLength uInt32Value]);

  [self sendMessageWithLength:msgLength message:message messageCode:msgCode];
  return [self listKeysGetResponse];
}

- (OFMutableArray *)listKeysGetResponse {
  RpbListKeysResp   pbMsg;
  OFMutableArray   *keys;
  OFNumber         *msgLength;
  OFNumber         *code;
  char             *message;
  BOOL              isDone = NO;
  int               keyIndex;

  keys = [[OFMutableArray array] retain];

  // @TODO: Proper response receiving
  while(!isDone) {
    msgLength = [[OFNumber numberWithUInt32:[socket readBigEndianInt32]]
                 numberByDecreasing];
    code      = [OFNumber numberWithUInt8:[socket readInt8]];

    if([msgLength uInt32Value] > 0) {
      message   = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]];
      [socket readNBytes:[msgLength uInt32Value] intoBuffer:message];

      pbMsg.ParseFromArray(message, [msgLength uInt32Value]);

      for(keyIndex = 0; keyIndex < pbMsg.keys_size(); keyIndex++) {
        [keys addObject:[[OFString stringWithCString:pbMsg.keys(keyIndex).c_str()
                                              length:pbMsg.keys(keyIndex).length()] retain]];
      }

      isDone = pbMsg.done();
    }
  }

  return keys;
}

- (OFDictionary *)getBucketProps:(OFString *)bucket {
  RpbGetBucketReq	pbMsg;
  char           *message;
  OFNumber       *msgLength;
  OFNumber       *msgCode;
  
  pbMsg.set_bucket([bucket cString]);
  
  msgCode   = [OFNumber numberWithUInt8:MC_GET_BUCKET_REQUEST];
  msgLength = [OFNumber numberWithUInt32:pbMsg.ByteSize()];
  message   = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]];
  
  pbMsg.SerializeToArray(message, [msgLength uInt32Value]);
  
  [self sendMessageWithLength:msgLength message:message messageCode:msgCode];
  return [self getBucketResponse];
}

- (OFDictionary *)getBucketResponse {
  RpbGetBucketResp pbMsg;
  OFNumber *msgLength;
  OFNumber *code;
  char     *message;

  // @TODO: Proper response receiving
  receiveResponse(msgLength, code, message);

  pbMsg.ParseFromArray(message, [msgLength uInt32Value]);
 
  return [[OFDictionary dictionaryWithKeysAndObjects:
           @"n_val",    	[OFNumber numberWithUInt32:pbMsg.props().n_val()],
           @"allow_mult", [OFNumber numberWithUInt32:pbMsg.props().allow_mult()],	nil]
          retain];
}

- (BOOL)setPropInBucket:(OFString *)bucket nVal:(uint32_t)nVal allowMult:(BOOL)isMult {
  
}

- (BOOL)setBucketResponse {
  
}

@end

