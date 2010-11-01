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
  nodeName  = [OFString stringWithString:node];
  nodePort  = [OFString stringWithString:port];

  [self connectToService:port onNode:node];

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

  nodeName 	= [OFString stringWithString:node];
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

  if([self receiveResponseWithCode:MC_GET_CLIENT_ID_RESPONSE inProtobuf:&protobuf])
    clientId  = *(int *)protobuf.client_id().c_str();
  else
    clientId  = 0;

  return [OFNumber numberWithInt:clientId];
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
    return [OFDictionary dictionaryWithKeysAndObjects:
             @"node",    [OFString stringWithCString:protobuf.node().c_str()
                                              length:protobuf.node().length()],
             @"version", [OFString stringWithCString:protobuf.server_version().c_str()
                                              length:protobuf.server_version().length()],
             nil];
  } else {
    return nil;
  }
}

- (OFDictionary *)getKey:(OFString *)key
              fromBucket:(OFString *)bucket
                  quorum:(uint32_t)quorum {

  RpbGetReq           request;
  RpbGetResp          response;
  OFDataArray         *contentsArray;
  OFDictionary        *keyDictionary;
  int                 iter;

  request.set_bucket([bucket cString]);
  request.set_key([key cString]);

  if(quorum) {
    request.set_r(quorum);
  }

  [self sendMessage:&request
           withCode:MC_GET_REQUEST];

  [self receiveResponseWithCode:MC_GET_RESPONSE
                     inProtobuf:&response];

  contentsArray = [OFDataArray dataArrayWithItemSize:sizeof(OFDictionary)];

  for(iter = 0; iter < response.content_size(); iter++) {
    [contentsArray addItem:[self unpackContent:response.content(iter)]];
  }

  keyDictionary = [OFDictionary dictionaryWithKeysAndObjects:
                    @"content", contentsArray,
                    @"vclock",  [OFString stringWithCString:response.vclock().c_str()
                                                   encoding:OF_STRING_ENCODING_ISO_8859_15
                                                     length:response.vclock().length()],
                    nil];

  return keyDictionary;
}

- (OFDictionary *)putKey:(OFString *)key
                inBucket:(OFString *)bucket
                  vClock:(OFString *)vClock
                 content:(OFDictionary *)content
                  quorum:(uint32_t)quorum
                  commit:(uint32_t)commit
              returnBody:(BOOL)returnBody {

  RpbPutReq       request;
  RpbPutResp      response;
  RpbContent      *pbContent = request.mutable_content();
  OFDictionary   *keyDictionary;
  OFDataArray    *contentsArray;
  int             iter;

  request.set_bucket([bucket cString]);
  request.set_key([key cString]);
  request.set_return_body(returnBody);

  if(commit)  request.set_dw(commit);
  if(quorum)  request.set_w(quorum);
  if(vClock)  request.set_vclock([vClock cString]);

  [self packContent:pbContent fromDictionary:content];
  [self sendMessage:&request withCode:MC_PUT_REQUEST];
  [self receiveResponseWithCode:MC_PUT_RESPONSE inProtobuf:&response];

  if(returnBody) {
    contentsArray = [OFDataArray dataArrayWithItemSize:sizeof(OFDictionary)];

    for(iter = 0; iter < response.content_size(); iter++)
      [contentsArray addItem:[self unpackContent:response.content(iter)]];

    keyDictionary  = [OFDictionary dictionaryWithKeysAndObjects:
                      @"content",    contentsArray,
                      @"vclock",     [OFString stringWithCString:response.vclock().c_str()
                                                        encoding:OF_STRING_ENCODING_ISO_8859_15
                                                          length:response.vclock().length()],
                      @"successful", @"YES",
                      nil];

    return keyDictionary;
  }

  return [OFDictionary dictionaryWithKeysAndObjects:
          @"successful",  @"YES",
          nil];
}

- (BOOL)deleteKey:(OFString *)key
       fromBucket:(OFString *)bucket
         replicas:(int)replicas {

  RpbDelReq protobuf;

  protobuf.set_bucket([bucket cString]);
  protobuf.set_key([key cString]);

  if(replicas)
    protobuf.set_rw(replicas);

  [self sendMessage:&protobuf withCode:MC_DEL_REQUEST];

  if([self receiveResponseWithCode:MC_DEL_RESPONSE inProtobuf:nil])
    return YES;
  else
    return NO;
}

- (OFDataArray *)listBucketsRequest {
  RpbListBucketsResp  protobuf;
  int                 iter;
  OFDataArray        *bucketList;
  
  bucketList = [[OFDataArray dataArrayWithItemSize:sizeof(OFString)] retain];

  [self sendEmptyRequestCode:MC_LIST_BUCKETS_REQUEST];

  [self receiveResponseWithCode:MC_LIST_BUCKETS_RESPONSE
                     inProtobuf:&protobuf];

  for(iter = 0; iter < protobuf.buckets_size(); iter++)
    [bucketList addItem:[OFString stringWithCString:protobuf.buckets(iter).c_str()
                                             length:protobuf.buckets(iter).length()]];

  return bucketList;
}


// @TODO: Create an Ostream C++ class and Serialize directly onto the socket buffer.
// @TODO: Delete pbMsg to clean up memory used.
- (OFDataArray *)listKeysInBucket:(OFString *)bucket {
  RpbListKeysReq  protobuf;

  protobuf.set_bucket([bucket cString]);

  [self sendMessage:&protobuf withCode:MC_LIST_KEYS_REQUEST];
  return [self listKeysGetResponse];
}

- (OFDataArray *)listKeysGetResponse {
  RpbListKeysResp   pbMsg;
  OFDataArray      *keys;
  OFNumber         *msgLength;
  OFNumber         *code;
  char             *message;
  BOOL              isDone = NO;
  int               keyIndex;

  keys = [[OFDataArray dataArrayWithItemSize:sizeof(OFString)] retain];

  // @TODO: Proper response receiving
  while(!isDone) {
    OFAutoreleasePool  *pool = [[OFAutoreleasePool alloc] init];

    msgLength = [[OFNumber numberWithUInt32:[socket readBigEndianInt32]]
                 numberByDecreasing];
    code      = [OFNumber numberWithUInt8:[socket readInt8]];

    if([msgLength uInt32Value] > 0) {
      
      message = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]];
      [socket readNBytes:[msgLength uInt32Value] intoBuffer:message];

      pbMsg.ParseFromArray(message, [msgLength uInt32Value]);

      for(keyIndex = 0; keyIndex < pbMsg.keys_size(); keyIndex++) {
        [keys addItem:[[OFString stringWithCString:pbMsg.keys(keyIndex).c_str()
                                            length:pbMsg.keys(keyIndex).length()] retain]];
      }

      isDone = pbMsg.done();
    }
    else {
      isDone = YES;
    }

    [pool drain];
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
            @"n_val",      [OFNumber numberWithUInt32:response.props().n_val()],
            @"allow_mult", [OFNumber numberWithUInt32:response.props().allow_mult()],
            nil];
  } else {
    return nil;
  }
}

- (BOOL)setForBucket:(OFString *)bucket nVal:(uint32_t)nVal allowMult:(BOOL)isMult {
  RpbSetBucketReq   request;
  RpbBucketProps   *properties = request.mutable_props();

  request.set_bucket([bucket cString]);
  properties->set_n_val(nVal);
  properties->set_allow_mult(isMult);

  [self sendMessage:&request withCode:MC_SET_BUCKET_REQUEST];

  if([self receiveResponseWithCode:MC_SET_BUCKET_RESPONSE inProtobuf:nil])
    return YES;
  else
    return NO;
}

- (OFDataArray *)mapReduceRequest:(OFString *)request
                    ofContentType:(OFString *)contentType {
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

