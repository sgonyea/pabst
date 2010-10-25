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
  self      = [super init];
  clientId  = nil;
  socket    = [OFTCPSocket socket];
  nodeName  = nil;
  nodePort  = nil;

  return self;
}

- (id)initWithService:(OFString *)port
               onNode:(OFString *)node {

  self      = [self init];

  [self connectToService:port onNode:node];

  nodeName  = [OFString stringWithString:node];
  nodePort  = [OFString stringWithString:port];

  return self;
}

/**
 * Shh! This is private!
 *  Connect to the riak node, identified in nodeName / nodePort
 */
- (void)connectToService {
  if(nodeName and nodePort) {
    [socket connectToService:nodePort onNode:nodeName];
    [socket setKeepAlivesEnabled:YES];
  }
}

- (void)connectToService:(OFString *)port
                  onNode:(OFString *)node {
  if(nodeName)
    [nodeName release];

  if(nodePort)
    [nodePort release];
  
  nodeName = [OFString stringWithString:node];
  nodePort  = [OFString stringWithString:port];

  [self connectToService];
}

- (void)sendEmptyRequestCode:(uint8_t)code {
  [socket bufferWrites];

  [socket writeBigEndianInt32:((uint32_t)MSG_CODE_SIZE)];
  [socket writeInt8:code];

  @try {
    [socket flushWriteBuffer];
  }
  @catch (OFNotConnectedException *e) {
    [self connectToService];
  }
  @finally {
    [socket flushWriteBuffer];
  }
}

- (void)sendEmptyMessageWithCode:(OFNumber *)msgCode {
  [self sendEmptyRequestCode:[msgCode uInt8Value]];
}

- (void)sendMessageWithLength:(OFNumber *)msgLength
                      message:(char *)message
                  messageCode:(OFNumber *)msgCode {

  [socket bufferWrites];

  [socket writeBigEndianInt32:[msgLength uInt32Value] + MC_SIZE];
  [socket writeInt8:[msgCode uInt8Value]];
  [socket writeNBytes:[msgLength uInt32Value] fromBuffer:message];

  [socket flushWriteBuffer];
}

- (void)dealloc {
  // Clean-up code here.
  [socket release];
  google::protobuf::ShutdownProtobufLibrary();
  [super dealloc];
}

- (BOOL)pingRiak {
  [self sendEmptyRequestCode:MC_PING_REQUEST];

  if([self receiveResponseWithCode:MC_PING_RESPONSE inProtobuf:nil])
    return YES;

  return NO;
}

- (OFNumber *)getClientId {
  [self sendEmptyRequestCode:MC_GET_CLIENT_ID_REQUEST];

  RpbGetClientIdResp protobuf;

  if([self receiveResponseWithCode:MC_GET_CLIENT_ID_RESPONSE inProtobuf:&protobuf]) {
    clientId = *(int *)protobuf.client_id().c_str();

    return [OFNumber numberWithInt:clientId];
  }
}

// @TODO: Rest of Set Client ID
- (BOOL)setClientId {
  RpbSetClientIdReq protobuf;
  
  if (!clientId) {
    [self getClientId];
  }
  protobuf.set_client_id((const void *)&clientId, sizeof(clientId));
  // @TODO: Set the client ID
  return YES;
}

- (OFDictionary *)getServerInfo {
  [self sendEmptyRequestCode:MC_GET_SERVER_INFO_REQUEST];

  RpbGetServerInfoResp protobuf;

  if([self receiveResponseWithCode:MC_GET_SERVER_INFO_RESPONSE inProtobuf:&protobuf]) {
    return [[OFDictionary dictionaryWithKeysAndObjects:
             @"node",    [OFString stringWithCString:protobuf.node().c_str()
                                              length:protobuf.node().length()],
             @"version", [OFString stringWithCString:protobuf.server_version().c_str()
                                              length:protobuf.server_version().length()],
             nil] retain];
  } else {
    return nil;
  }
}

- (OFDictionary *)getKey:(OFString *)key
              fromBucket:(OFString *)bucket
                  quorum:(uint32_t)quorum {

  RpbGetReq     request;
  RpbGetResp    response;
  OFDataArray  *contentsArray;
  int           iter;

  request.set_bucket([bucket cString]);
  request.set_key([key cString]);

  if(quorum) {
    request.set_r(quorum);
  }

  [self sendMessage:&request withCode:MC_GET_REQUEST];

  [self receiveResponseWithCode:MC_GET_RESPONSE inProtobuf:&response];
  
  contentsArray = [[OFDataArray dataArrayWithItemSize:sizeof(OFDictionary)] retain];
  
  for(iter = 0; iter < response.content_size(); iter++)
    [contentsArray addItem:[self unpackContent:response.content(iter)]];
  
  return [OFDictionary dictionaryWithKeysAndObjects:
          @"content", contentsArray,
          @"vclock",  [OFString stringWithCString:response.vclock().c_str()
                                         encoding:OF_STRING_ENCODING_ISO_8859_15
                                           length:response.vclock().length()],
          nil];
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

- (OFDictionary *)getBucket:(OFString *)bucket {
  RpbGetBucketReq   request;
  RpbGetBucketResp  response;

  request.set_bucket([bucket cString]);
  
  [self sendMessage:&request withCode:MC_GET_BUCKET_REQUEST];

  if([self receiveResponseWithCode:MC_GET_BUCKET_RESPONSE inProtobuf:&response]) {
    return [OFDictionary dictionaryWithKeysAndObjects:
             @"n_val",    	[OFNumber numberWithUInt32:response.props().n_val()],
             @"allow_mult", [OFNumber numberWithUInt32:response.props().allow_mult()],
             nil];
  } else {
    return nil;
  }
}

- (BOOL)setPropInBucket:(OFString *)bucket nVal:(uint32_t)nVal allowMult:(BOOL)isMult {
  RpbSetBucketReq   pbMsg;
  RpbBucketProps   *bProp = pbMsg.mutable_props();
  char             *message;
  OFNumber         *msgLength;
  OFNumber         *msgCode;

  pbMsg.set_bucket([bucket cString]);
  bProp->set_n_val(nVal);
  bProp->set_allow_mult(isMult);

  msgCode   = [OFNumber numberWithUInt8:MC_SET_BUCKET_REQUEST];
  msgLength = [OFNumber numberWithUInt32:pbMsg.ByteSize()];
  message   = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]];
  
  pbMsg.SerializeToArray(message, [msgLength uInt32Value]);
  
  [self sendMessageWithLength:msgLength message:message messageCode:msgCode];
  return [self setBucketResponse];
}

- (BOOL)setBucketResponse {
  OFNumber *msgLength;
  OFNumber *code;
  char     *message;

  // @TODO: Proper response receiving
  receiveResponse(msgLength, code, message);
  return YES;
}

- (OFDataArray *)mapReduceRequest:(OFString *)request ofContentType:(OFString *)contentType {
  RpbMapRedReq   pbMsg;
  char          *message;
  OFNumber      *msgLength;
  OFNumber      *msgCode;
  
  pbMsg.set_request([request cString]);
  pbMsg.set_content_type([contentType cString]);

  msgCode   = [OFNumber numberWithUInt8:MC_MAP_REDUCE_REQUEST];
  msgLength = [OFNumber numberWithUInt32:pbMsg.ByteSize()];
  message   = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]];

  pbMsg.SerializeToArray(message, [msgLength uInt32Value]);

  [self sendMessageWithLength:msgLength message:message messageCode:msgCode];
  return [self mapReduceResponse];  
}

- (OFDataArray *)mapReduceResponse {
  RpbMapRedResp     pbMsg;
  OFDataArray      *reduceResponses = [[OFDataArray dataArrayWithItemSize:sizeof(OFDictionary)] retain];
  OFNumber         *msgLength;
  OFNumber         *code;
  char             *message;
  BOOL              isDone = NO;

  // @TODO: Proper response receiving
  while(!isDone) {
    msgLength = [[OFNumber numberWithUInt32:[socket readBigEndianInt32]]
                 numberByDecreasing];
    code      = [OFNumber numberWithUInt8:[socket readInt8]];

    if([msgLength uInt32Value] > 0) {
      message   = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]];
      [socket readNBytes:[msgLength uInt32Value] intoBuffer:message];

      pbMsg.ParseFromArray(message, [msgLength uInt32Value]);

      if(pbMsg.has_response()) {
        [reduceResponses addItem:[OFDictionary dictionaryWithObject:[OFString stringWithCString:pbMsg.response().c_str()
                                                                                         length:pbMsg.response().length()]
                                                             forKey:[OFNumber numberWithUInt32:pbMsg.phase()]]];
      }

      isDone = pbMsg.done();
    } else {
      isDone = YES; // This should never happen? @TODO: Verify
    }
  }

  return reduceResponses;
}

@end

