//
//  RiakProtobuf.h
//  riak_pb-objc
//
//  Created by Scott Gonyea on 9/1/10.
//
#import <ObjFW/ObjFW.h>
#import "MessageCodes.h"

@interface RiakProtobuf : OFObject {
  OFTCPSocket  *socket;
  OFNumber     *clientId;
@private
}
/**
 *  Initialize the RiakProtobuf
 */
- (id)init;

/**
 *  Initialize the RiakProtobuf with port/hostname for a riak node
 */
- (id)initWithService:(OFString *)port
               onNode:(OFString *)node;

/**
 *  Connect to a riak node's port/hostname
 */
- (void)connectToService:(OFString *)port
                  onNode:(OFString *)node;

/**
 *  Send a request who's only content is a Message Code
 */
- (void)sendEmptyMessageWithCode:(OFNumber *)msgCode;

/**
 *  Send a request made up of a Message Code and a serialized Protobuf
 */
- (void)sendMessageWithLength:(OFNumber *)length
                      message:(char *)message
                  messageCode:(OFNumber *)code;

/**
 *  De-allocate
 */
- (void)dealloc;

/**
 *  Protobuf containing an error message
 */
- (OFDictionary *)errorResponse:(char *)response;


/* Ping */
/**
 *  Request
 *    Send Message Code, Only
 */
- (BOOL)pingRequest;  // Message Code Only
/**
 *  Response
 *    riak sends Message Code, Only, as confirmation
 */
- (BOOL)pingGetResponse;


/* Get Client ID */
/**
 *  Request
 *    Send Message Code, Only
 */
- (OFNumber *)getClientId;
/**
 *  Response
 *    riak sends a 4-byte value
 */
- (OFNumber *)clientIdGetResponse;


/* Set Client ID */
/**
 *  Request
 *    Send the Client ID cached in RiakProtobuf
 */
- (BOOL)setClientId;
/**
 *  Request
 *    Send an arbitrary Client ID to riak
 */
- (BOOL)setClientId:(OFString *)clientId;
/**
 *  Response
 *    riak sends Message Code, Only, as confirmation
 */
- (BOOL)setClientIdResponse;


/* Get Server Information */
/**
 *  Request
 *    Send Message Code, Only
 */
- (OFDictionary *)getServerInfoRequest;
/**
 *  Response
 *    riak sends two values: the name of the node (1) and the server version (2)
 */
- (OFDictionary *)getServerInfoResponse;


/* Get (Key) Request */
/**
 *  Request
 *    Send the name of the bucket (1), the key (2), and the quorum (3)
 */
- (OFDictionary *)getKey:(OFString *)key
              fromBucket:(OFString *)bucket
                  quorum:(OFNumber *)quorum;
/**
 *  Response
 *    riak sends two values: the bucket+key's vclock (1) and content(s) on the key (2)
 */
- (OFDictionary *)getKeyResponse;


/* Put (Key) Request */
/**
 *  Request
 *    Send the name of the bucket (1), the key (2), the key's content (3), the quorum (4), and the commits-before-ack (5)
 */
- (OFDictionary *)putKey:(OFString *)key
                inBucket:(OFString *)bucket
                  vClock:(OFString *)vClock
                 content:(OFMutableDictionary *)content
                  quorum:(uint32_t)quorum
                  commit:(uint32_t)commit
              returnBody:(BOOL)returnBody;
/**
 *  Response
 *    riak sends just a message code, confirming that it done got putted
 */
- (OFDictionary *)putResponse;
/**
 *  Response
 *    riak sends two values: the bucket+key's vclock (1) and content(s) on the key (2)
 */
- (OFDictionary *)putResponseAndGetBody;


/* Delete (Key) Request */
/**
 *  Request
 *    Send the name of the bucket (1), the key name (2), and the num replicas that should confirm deletion (3)
 */
- (BOOL)deleteKey:(OFString *)key
       fromBucket:(OFString *)bucket
         replicas:(int)replicas;
/**
 *  Response
 *    riak sends Message Code, Only, as confirmation
 */
- (BOOL)deleteKeyResponse;


/* List Buckets Request */
/**
 *  Request
 *    Send Message Code, Only
 */
- (OFDataArray *)listBucketsRequest;
/**
 *  Request
 *    Send Message Code, Only
 */
- (OFDataArray *)listBucketsResponse;

- (OFMutableArray *)listKeysInBucket:(OFString *)bucket;
- (OFMutableArray *)listKeysGetResponse;

- (OFDictionary *)getBucket:(OFString *)bucket;
- (OFDictionary *)getBucketResponse;

- (BOOL)setPropInBucket:(OFString *)bucket
                   nVal:(OFNumber *)nVal
                 isMult:(BOOL)isMult;
- (BOOL)setBucketResponse; // Message Code Only

- (OFDictionary *)mapReduceRequest:(char *)request
                       contentType:(OFString *)contentType;
- (OFDictionary *)mapReduceResponse;

@end
