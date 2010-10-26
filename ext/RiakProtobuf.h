//
//  RiakProtobuf.h
//  riak_pb-objc
//
//  Created by Scott Gonyea on 9/1/10.
//
#import <ObjFW/ObjFW.h>
#import "MessageCodes.h"
#import "ErrorResponseException.h"

@interface RiakProtobuf : OFObject {
  OFTCPSocket  *socket;
  int           clientId;
  OFString     *nodeName;
  OFString     *nodePort;
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
 *  Send a request made up of a Message Code and a serialized Protobuf
 */
- (void)sendMessageWithLength:(OFNumber *)length
                      message:(char *)message
                  messageCode:(OFNumber *)code;

/**
 *  De-allocate
 */
- (void)dealloc;

//@TODO: Handler for errors?  Specific method needed?
/**
 *  Protobuf containing an error message
 */
//- (OFDictionary *)errorResponse:(char *)response;


/** Ping
 **
 *  Request
 *    Send Message Code, Only
 *
 *  Response
 *    riak sends Message Code, Only, as confirmation
 */
- (BOOL)pingRiak;


/** Get Client ID
 **
 *  Request
 *    Send Message Code, Only
 *
 *  Response
 *    riak sends a 4-byte value
 */
- (OFNumber *)getClientId;
/**


// @TODO: refactor / implement
/* Set Client ID */
/**
 *  Request
 *    Send the Client ID cached in RiakProtobuf
 */
- (BOOL)setClientId;


/** Get Server Information
 **
 *  Request
 *    Send Message Code, Only
 *
 *  Response
 *    riak sends two values: the name of the node (1) and the server version (2)
 */
- (OFDictionary *)getServerInfo;


/** Get Key from Bucket Request
 **
 *  Request
 *    Send the name of the bucket (1), the key (2), and the quorum (3)
 *
 *  Response
 *    riak sends two values: the bucket+key's vclock (1) and content(s) on the key (2)
 */
- (OFDictionary *)getKey:(OFString *)key
              fromBucket:(OFString *)bucket
                  quorum:(uint32_t)quorum;


// @TODO: refactor more
/** Put Key in Bucket Request
 **
 *  Request
 *    Send the name of the bucket (1), the key (2), the key's content (3), the quorum (4), and the commits-before-ack (5)
 *
 *  Response
 *    riak sends either the message code or (optionally) two values: the bucket+key's vclock (1) and content(s) on the key (2)
 */
- (OFDictionary *)putKey:(OFString *)key
                inBucket:(OFString *)bucket
                  vClock:(OFString *)vClock
                 content:(OFDictionary *)content
                  quorum:(uint32_t)quorum
                  commit:(uint32_t)commit
              returnBody:(BOOL)returnBody;


/** Delete Key from Bucket Request
 **
 *  Request
 *    Send the name of the bucket (1), the key name (2), and the num replicas that should confirm deletion (3)
 *
 *  Response
 *    riak sends Message Code, Only, as confirmation
 */
- (BOOL)deleteKey:(OFString *)key
       fromBucket:(OFString *)bucket
         replicas:(int)replicas;


/** List Buckets Request
 **
 *  Request
 *    Send Message Code, Only
 *
 *  Response
 *    Sends the list of bucket names
 */
- (OFDataArray *)listBucketsRequest;


/* List Keys Request */
/**
 *  Request
 *    Send the name of the bucket, in which keys should be listed
 */
- (OFDataArray *)listKeysInBucket:(OFString *)bucket;
/**
 *  Response
 *    Streams the list of Keys, until done
 */
- (OFDataArray *)listKeysGetResponse;


/** Get Bucket Properties
 **
 *  Request
 *    Send the name of the bucket
 *
 *  Response
 *    Sends the bucket's active properties
 */
- (OFDictionary *)getBucket:(OFString *)bucket;


/** Set Bucket Properties
 **
 *  Request
 *    Send the name of the bucket and the Properties, to be set
 *
 *  Request
 *    Message Code Only
 */
- (BOOL)setForBucket:(OFString *)bucket
                nVal:(uint32_t)nVal
           allowMult:(BOOL)isMult;


/* Map/Reduce Request */
/**
 *  Request
 *    Send the request (String) and the type of request, describing how to parse
 */
- (OFDataArray *)mapReduceRequest:(OFString *)request
                    ofContentType:(OFString *)contentType;
/**
 *  Response
 *    Streams the Map/Reduce response until done
 */
- (OFDataArray *)mapReduceResponse;

@end
