
#import "OFDictionary+Ruby.h"
#import "ObjFW+Ruby.h"

@implementation OFDictionary (Ruby)

- (VALUE)toRuby {
  VALUE rb_returnHash = rb_hash_new();

  [self enumerateKeysAndObjectsUsingBlock:
   ^(id key, id obj, BOOL *stop) {
     VALUE keyValue = [key toRuby];
     VALUE objValue = [obj toRuby];
     
     if (!keyValue) { // not! keyValue
       keyValue = Qnil;
     }
     if (!objValue) { // not! objValue
       objValue = Qnil;
     }
     
     rb_hash_aset(rb_returnHash, keyValue, objValue);
   }];

  return rb_returnHash;
}

- (VALUE)toRubyWithSymbolicKeys {
  VALUE rb_returnHash = rb_hash_new();

  [self enumerateKeysAndObjectsUsingBlock:
   ^(id key, id obj, BOOL *stop) {
     VALUE objValue = [obj toRuby];
     VALUE keyValue;

     if([key respondsToSelector:@selector(toRubySymbol)])
       keyValue = [key toRubySymbol];
     else
       keyValue = [key toRuby];

     if(!keyValue)
       keyValue = Qnil;

     if(!objValue)
       objValue = Qnil;

     rb_hash_aset(rb_returnHash, keyValue, objValue);
   }];

  return rb_returnHash;
}
@end
