/*
 *  RiakProtobuf+Cpp.mm
 *  riak_pb-objc
 *
 *  Created by Scott Gonyea on 10/16/10.
 *
 */

#import "RiakProtobuf+Cpp.h"
#import <exception>

@implementation RiakProtobuf (Cpp)

- (void)sendMessage:(google::protobuf::Message *)protobuf
           withCode:(uint8_t)code {

  OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
  uint32_t    pbLength;
  char       *pbMessage;

    pbLength  = protobuf->ByteSize();
    pbMessage = (char *)[self allocMemoryWithSize:pbLength];

    protobuf->SerializeToArray(pbMessage, pbLength);

    [socket bufferWrites];

    [socket writeBigEndianInt32:(pbLength + MC_SIZE)];
    [socket writeInt8:code];
    [socket writeNBytes:pbLength fromBuffer:pbMessage];

    [socket flushWriteBuffer];
//  }
/* @TODO: Do some exception handling */
//  catch (std::exception& e) {
    /* blah */
//  }
/*} catch (IOException &e) {

  } catch (RuntimeException &e) {

  }
*/
  [pool release];
}

- (int8_t)receiveResponseWithCode:(int8_t)expectedCode
                       inProtobuf:(google::protobuf::Message *)protobuf {

  OFAutoreleasePool *pool = [[OFAutoreleasePool alloc] init];
  uint32_t  msgLength;
  int8_t    msgCode;
  char     *message;

  msgLength = [socket readBigEndianInt32];
  msgCode   = [socket readInt8];

  if(msgLength > 0 && protobuf != nil) {
    message   = (char *)[self allocMemoryWithSize:msgLength];
    [socket readNBytes:msgLength intoBuffer:message];

    if(msgCode == expectedCode) {
      protobuf->ParseFromArray(message, msgLength);

    } else if(msgCode == MC_ERROR_RESPONSE) {
      RpbErrorResp error;
      error.ParseFromArray(message, msgLength);
      [pool release];
      @throw [ErrorResponseException newWithClass:isa
                                     errorCString:error.errmsg().c_str()
                                        errorCode:error.errcode()];
    } else {
      [pool release];
      @throw [ErrorResponseException newWithClass:isa
                                      errorString:@"Unknown Exception Occured. Expected Message Code not received, yet an Error was not indicated. Bug?"
                                        errorCode:-1];
    }
  }
  [pool release];
  return msgCode;
}

- (OFMutableDictionary *)unpackContent:(RpbContent)pbContent {
  OFString 						*contentValue 		= nil,
           						*contentType			= nil,
           						*contentCharset		= nil,
           						*contentEncoding	= nil,
           						*contentVtag			= nil;
  OFNumber						*contentLastMod		= nil,
          						*contentUsecs			= nil;
  OFDataArray					*contentLinks			= nil,
  										*contentMetas			= nil;
  

  int iter;
  
  if(pbContent.has_value())
    contentValue 		= [[OFString stringWithCString:pbContent.value().c_str()
                 	  	                      length:pbContent.value().length()] retain];

  if(pbContent.has_content_type())
    contentType 		= [[OFString stringWithCString:pbContent.content_type().c_str()
                    	                      length:pbContent.content_type().length()] retain];

  if(pbContent.has_charset())
    contentCharset	= [[OFString stringWithCString:pbContent.charset().c_str()
                                  	        length:pbContent.charset().length()] retain];
  
  if(pbContent.has_content_encoding())
    contentEncoding = [[OFString stringWithCString:pbContent.content_encoding().c_str()
                    	                      length:pbContent.content_encoding().length()] retain];
  
  if(pbContent.has_vtag())
    contentVtag 		= [[OFString stringWithCString:pbContent.vtag().c_str()
                                        	encoding:OF_STRING_ENCODING_ISO_8859_15
                                         		length:pbContent.vtag().length()] retain];
  
  if(pbContent.has_last_mod())
    contentLastMod 	= [[OFNumber  numberWithUInt32:pbContent.last_mod()] retain];
  
  if(pbContent.has_last_mod_usecs())
    contentUsecs 		= [[OFNumber  numberWithUInt32:pbContent.last_mod_usecs()] retain];
  
  if(pbContent.links_size() > 0)
    contentLinks		= [[self unpackLinksFromContent:pbContent] retain];

  if(pbContent.usermeta_size() > 0)
    contentMetas		= [[self unpackUserMetaFromContent:pbContent] retain];

  return [[OFDictionary dictionaryWithKeysAndObjects:
           @"value", 						contentValue,
           @"content_type", 		contentType,
           @"charset", 					contentCharset,
           @"content_encoding", contentEncoding,
           @"vtag", 						contentVtag,
           @"last_mod", 				contentLastMod,
           @"last_mod_usecs", 	contentUsecs,
           @"links", 						contentLinks,
           @"user_meta", 				contentMetas,
           nil]
          retain];
}

// @TODO: Do
- (void)packContent:(RpbContent *)pbContent fromDictionary:(OFDictionary *)content {
  

	if([content objectForKey:@"value"])
		pbContent->set_value([[content objectForKey:@"value"] cString]);

	if([content objectForKey:@"content_type"])
		pbContent->set_content_type([[content objectForKey:@"content_type"] cString]);
  
  if([content objectForKey:@"charset"])
		pbContent->set_charset([[content objectForKey:@"charset"] cString]);
  
  if([content objectForKey:@"content_encoding"])
		pbContent->set_content_encoding([[content objectForKey:@"content_encoding"] cString]);
  
  if([content objectForKey:@"vtag"])
		pbContent->set_vtag([[content objectForKey:@"vtag"] cString]);
  
  if([content objectForKey:@"last_mod"])
		pbContent->set_last_mod([[content objectForKey:@"last_mod"] uInt32Value]);
  
  if([content objectForKey:@"last_mod_usecs"])
		pbContent->set_last_mod_usecs([[content objectForKey:@"last_mod_usecs"] uInt32Value]);

  if([content objectForKey:@"links"])
    [self packLinks:[content objectForKey:@"links"] inContent:pbContent];

  if([content objectForKey:@"user_meta"])
		[self packUserMeta:[content objectForKey:@"user_meta"] inContent:pbContent];
}

- (OFDataArray *)unpackLinksFromContent:(RpbContent)pbContent {
  OFDataArray  *linksArray = [OFDataArray dataArrayWithItemSize:pbContent.links_size()];
  int           iter;

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
  return linksArray;
}

// @TODO: Do
- (void)packLinks:(OFDataArray *)links inContent:(RpbContent *)pbContent {
  size_t iter;

  for(iter = 0;  iter < [links count]; iter++) {
    RpbLink      *_pblink = pbContent->add_links();
    OFDictionary *_rbLink = (OFDictionary *)[links itemAtIndex:iter];

    if([_rbLink objectForKey:@"bucket"])
      _pblink->set_bucket([[_rbLink objectForKey:@"bucket"] cString]);

    if([_rbLink objectForKey:@"key"])
      _pblink->set_key([[_rbLink objectForKey:@"key"] cString]);

    if([_rbLink objectForKey:@"tag"])
      _pblink->set_tag([[_rbLink objectForKey:@"tag"] cString]);
  }
}

- (OFDataArray *)unpackUserMetaFromContent:(RpbContent)pbContent {
  OFDataArray  *userMetaArray = [OFDataArray dataArrayWithItemSize:pbContent.usermeta_size()];
  int           iter;
  
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
  return userMetaArray;
}

// @TODO: Do
- (void)packUserMeta:(OFDataArray *)userMeta inContent:(RpbContent *)pbContent {
  size_t iter;

  for(iter = 0;  iter < [userMeta count]; iter++) {
    RpbPair      *_pbMeta = pbContent->add_usermeta();
    OFDictionary *_rbMeta = (OFDictionary *)[userMeta itemAtIndex:iter];
    
    if([_rbMeta objectForKey:@"key"]) {
      _pbMeta->set_key([[_rbMeta objectForKey:@"key"] cString]);
    }
    if([_rbMeta objectForKey:@"value"]) {
      _pbMeta->set_value([[_rbMeta objectForKey:@"value"] cString]);
    }
  }
}

@end
