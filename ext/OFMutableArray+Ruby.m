
#import "OFMutableArray+Ruby.h"
#import "ObjFW+Ruby.h"

@implementation OFMutableArray (Ruby)
- (VALUE)toRuby {
  VALUE rb_returnArray = rb_ary_new2([self count]);
  size_t iter;
  id tmpObject;
  
  for(iter = 0; iter < [self count]; iter++) {
    tmpObject = [self objectAtIndex:iter];
    
    if([tmpObject respondsToSelector:@selector(toRuby)])
      rb_ary_store(rb_returnArray, iter, [tmpObject toRuby]);
    else
      rb_ary_store(rb_returnArray, iter, Qnil);
  }
  
  return rb_returnArray;
}

- (VALUE)toRubyWithSymbolicKeys {
  VALUE rb_returnArray = rb_ary_new2([self count]);
  size_t iter;
  id tmpObject;

  for(iter = 0; iter < [self count]; iter++) {
    tmpObject = [self objectAtIndex:iter];
    
    if([tmpObject respondsToSelector:@selector(toRubyWithSymbolicKeys)])
      rb_ary_store(rb_returnArray, iter, [tmpObject toRubyWithSymbolicKeys]);
    else if([tmpObject respondsToSelector:@selector(toRuby)])
      rb_ary_store(rb_returnArray, iter, [tmpObject toRuby]);
    else
      rb_ary_store(rb_returnArray, iter, Qnil);
  }
  
  return rb_returnArray;
}
@end
