
#import "OFDictionary+Ruby.h"
#import "ObjFW+Ruby.h"

@implementation OFDictionary (Ruby)

- (VALUE)toRuby {
  VALUE rb_returnHash = rb_hash_new();

  [self enumerateKeysAndObjectsUsingBlock:
   ^(id key, id obj, BOOL *stop) {
     VALUE keyValue;
     VALUE objValue;

     if([key respondsToSelector:@selector(toRuby)])
       keyValue = [key toRuby];
     else
       keyValue = Qnil;

     if([obj respondsToSelector:@selector(toRuby)])
       objValue = [obj toRuby];
     else
       objValue = Qnil;
     
     rb_hash_aset(rb_returnHash, keyValue, objValue);
   }];

  return rb_returnHash;
}

- (VALUE)toRubyWithSymbolicKeys {
  VALUE rb_returnHash = rb_hash_new();

  [self enumerateKeysAndObjectsUsingBlock:
   ^(id key, id obj, BOOL *stop) {
     VALUE objValue;
     VALUE keyValue;

     if([key respondsToSelector:@selector(toRubySymbol)])
       keyValue = [key toRubySymbol];
     else if([key respondsToSelector:@selector(toRuby)])
       keyValue = [key toRuby];
     else
       keyValue = Qnil;

     if([obj respondsToSelector:@selector(toRuby)])
       objValue = [obj toRuby];
     else
       objValue = Qnil;

     rb_hash_aset(rb_returnHash, keyValue, objValue);
   }];

  return rb_returnHash;
}
@end
