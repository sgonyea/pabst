//
//  ErrorResponseException.m
//  pabst
//
//  Created by Scott Gonyea on 10/24/10.
//

#import "ErrorResponseException.h"

@implementation ErrorResponseException

+(id) newWithClass:(Class)class_ errorString:(OFString *)error {
  return [[self alloc] initWithClass:class_ errorString:error];
}

+(id) newWithClass:(Class)class_ errorCString:(char *)error {
  return [[self alloc] initWithClass:class_ errorCString:error];
}

-(id) initWithClass:(Class)class_ errorString:(OFString *)error {
  self = [super initWithClass: class_];

  string = [[OFString alloc] initWithFormat:
            @"Riak responded with an error:%s", [error cString]];

  return self;
}

-(id) initWithClass:(Class)class_ errorCString:(char *)error {
  self = [super initWithClass: class_];

  string = [[OFString alloc] initWithFormat:
            @"Riak responded with an error:%s", error];

  return self;
}

@end
