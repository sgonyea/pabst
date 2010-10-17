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

- (OFMutableDictionary *)unpackContent:(RpbContent)pbContent {
  OFMutableDictionary *content = [[OFMutableDictionary dictionary] retain];
  int iter;

  if(pbContent.has_value()) {
    [content setObject:[OFString stringWithCString:pbContent.value().c_str()
                                            length:pbContent.value().length()]
                forKey:@"value"];
  }

  if(pbContent.has_content_type()) {
    [content setObject:[OFString stringWithCString:pbContent.content_type().c_str()
                                            length:pbContent.content_type().length()]
                forKey:@"content_type"];
  }

  if(pbContent.has_charset()) {
    [content setObject:[OFString stringWithCString:pbContent.charset().c_str()
                                            length:pbContent.charset().length()]
                forKey:@"charset"];
  }

  if(pbContent.has_content_encoding()) {
    [content setObject:[OFString stringWithCString:pbContent.content_encoding().c_str()
                                            length:pbContent.content_encoding().length()]
                forKey:@"content_encoding"];
  }

  if(pbContent.has_vtag()) {
    [content setObject:[OFString stringWithCString:pbContent.vtag().c_str()
                                            length:pbContent.vtag().length()]
                forKey:@"vtag"];
  }

  if(pbContent.has_last_mod()) {
    [content setObject:[OFNumber numberWithUInt32:pbContent.last_mod()]
                forKey:@"last_mod"];
  }

  if(pbContent.has_last_mod_usecs()) {
    [content setObject:[OFNumber numberWithUInt32:pbContent.last_mod_usecs()]
                forKey:@"last_mod_usecs"];
  }

  if(pbContent.links_size() > 0) {
    OFDataArray *linksArray = [OFDataArray dataArrayWithItemSize:pbContent.links_size()];

    for(iter = 0; iter < pbContent.links_size(); iter++) {
      RpbLink link = pbContent.links(iter);
      [linksArray addItem:[OFDictionary dictionaryWithKeysAndObjects:
                            @"bucket",  [OFString stringWithCString:link.bucket().c_str()
                                                             length:link.bucket().length()],

                            @"key",     [OFString stringWithCString:link.key().c_str()
                                                             length:link.key().length()],

                            @"tag",     [OFString stringWithCString:link.tag().c_str()
                                                             length:link.tag().length()],

                            nil]
                  atIndex:iter];
    }

    [content setObject:linksArray
                forKey:@"links"];
  }


  if(pbContent.usermeta_size() > 0) {
    OFDataArray *userMetaArray = [OFDataArray dataArrayWithItemSize:pbContent.usermeta_size()];

    for(iter = 0; iter < pbContent.usermeta_size(); iter++) {
      RpbPair userMeta = pbContent.usermeta(iter);
      [userMetaArray addItem:[OFDictionary dictionaryWithKeysAndObjects:
                                @"key",     [OFString stringWithCString:userMeta.key().c_str()
                                                                 length:userMeta.key().length()],
                                @"value",   [OFString stringWithCString:userMeta.value().c_str()
                                                                 length:userMeta.value().length()],
                                nil]
                     atIndex:iter];
    }

    [content setObject:userMetaArray
                forKey:@"user_meta"];
  }

  return content;
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

- (OFNumber *)clientIdRequest {
  [self sendEmptyMessageWithCode:[OFNumber numberWithUInt8:MC_GET_CLIENT_ID_REQUEST]];
  return [self clientIdGetResponse];
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

// @TODO: Set Client ID

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

