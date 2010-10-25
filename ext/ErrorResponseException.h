//
//  ErrorResponseException.h
//  pabst
//
//  Created by Scott Gonyea on 10/24/10.
//
#import "ObjFW/OFExceptions.h"
#import "RiakProtobuf.h"

@interface ErrorResponseException : OFException {
}

+(id) newWithClass:(Class)class_
       errorString:(OFString *)error
         errorCode:(int)code;

+(id) newWithClass:(Class)class_
      errorCString:(const char *)error
         errorCode:(int)code;

-(id) initWithClass:(Class)class_
        errorString:(OFString *)error
          errorCode:(int)code;

-(id) initWithClass:(Class)class_
       errorCString:(const char *)error
          errorCode:(int)code;

@end
