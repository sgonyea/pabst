
#import "OFDictionary+Ruby.h"

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
@end
