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
#import "riakclient.pb.h"

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

  receiveResponse(msgLength, code, message);

  return YES;
}

- (OFNumber *)getClientId {
  [self sendEmptyMessageWithCode:[OFNumber numberWithUInt8:MC_GET_CLIENT_ID_REQUEST]];

  OFNumber *newClientId = [self clientIdGetResponse];

  client_id = [newClientId copy];

  return newClientId;
}

- (OFNumber *)clientIdGetResponse {
  RpbGetClientIdResp pbMsg;
  OFNumber *msgLength;
  OFNumber *code;
  char     *message;

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
  // @TODO: Set the client ID
  return YES;
}

- (OFDictionary *)getServerInfoRequest {
  [self sendEmptyMessageWithCode:[OFNumber numberWithUInt8:MC_GET_SERVER_INFO_REQUEST]];
  return [self getServerInfoResponse];
}

- (OFDictionary *)getServerInfoResponse {
  RpbGetServerInfoResp pbMsg;
  OFDictionary  *response;
  OFNumber *msgLength;
  OFNumber *code;
  char     *message;

  receiveResponse(msgLength, code, message);

  pbMsg.ParseFromArray(message, [msgLength uInt32Value]);

  response = [OFDictionary dictionaryWithKeysAndObjects:
                @"node",    [OFString stringWithCString:pbMsg.node().c_str()
                                                 length:pbMsg.node().length()],

                @"version", [OFString stringWithCString:pbMsg.server_version().c_str()
                                                 length:pbMsg.server_version().length()],

                nil];

  return [response retain];
}

- (OFDictionary *)getFromBucket:(OFString *)bucket atKey:(OFString *)key quorum:(OFNumber *)quorum {
  RpbGetReq   pbMsg;
  char       *message;
  OFNumber   *msgLength;
  OFNumber   *msgCode;

  pbMsg.set_bucket([bucket cString]);
  pbMsg.set_key([key cString]);

  if(quorum) {
    pbMsg.set_r([quorum uInt32Value]);
  }

  msgCode   = [OFNumber numberWithUInt8:MC_LIST_KEYS_REQUEST];
  msgLength = [OFNumber numberWithUInt32:pbMsg.ByteSize()];
  message   = (char *)[self allocMemoryWithSize:[msgLength uInt32Value]];

  pbMsg.SerializeToArray(message, [msgLength uInt32Value]);

  [self sendMessageWithLength:msgLength message:message messageCode:msgCode];
  return [self getKeyResponse];
}

- (OFDictionary *)getKeyResponse {
  RpbGetResp      pbMsg;
  RpbContent      content;
  OFDataArray    *contentArray;
  OFDictionary   *response;
  OFNumber       *msgLength;
  OFNumber       *code;
  char           *message;
  int             i;

  receiveResponse(msgLength, code, message);

  pbMsg.ParseFromArray(message, [msgLength uInt32Value]);

  [contentArray initWithItemSize:pbMsg.content_size()];

  for(i = 0; i < pbMsg.content_size(); i++) {
    content = pbMsg.content(i);

    [contentArray addItem:[self unpackContent:content]
                  atIndex:i];
  }

  response = [OFDictionary dictionaryWithKeysAndObjects:
                @"content", contentArray,
                @"vclock",  [OFString stringWithCString:pbMsg.vclock().c_str()
                                                 length:pbMsg.vclock().length()],

                nil];

  return [response retain];
}

// @TODO: Create an Ostream C++ class and Serialize directly onto the socket buffer.
// @TODO: Delete pbMsg to clean up memory used.
- (OFMutableArray *)listKeysInBucket:(OFString *)bucket {
  RpbListKeysReq pbMsg;
  char     *message;
  OFNumber *msgLength;
  OFNumber *msgCode;

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

  receiveResponse(msgLength, code, message);

  pbMsg.ParseFromArray(message, [msgLength uInt32Value]);

  if(pbMsg.has_done()) {
    isDone = pbMsg.done();
  }

  for(keyIndex = 0; keyIndex < pbMsg.keys_size(); keyIndex++) {
    [keys addObject:[OFString stringWithCString:pbMsg.keys(keyIndex).c_str()]];
  }

  return keys;
}

@end

