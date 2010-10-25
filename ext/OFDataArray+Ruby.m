
#import "OFDataArray+Ruby.h"
#import "ObjFW+Ruby.h"

@implementation OFDataArray (Ruby)

- (VALUE)toRuby {
  VALUE rb_returnArray = rb_ary_new2([self count]);
  size_t iter;
  id tmpItem;

  for(iter = 0; iter < [self count]; iter++) {
    tmpItem = [self itemAtIndex:iter];
    if([tmpItem respondsToSelector:@selector(toRuby)])
      rb_ary_store(rb_returnArray, iter, [tmpItem toRuby]);
    else
      rb_ary_store(rb_returnArray, iter, Qnil);
  }

  return rb_returnArray;
}

- (VALUE)toRubyWithSymbolicKeys {

  VALUE rb_returnArray = rb_ary_new2([self count]);
  size_t iter;
  id tmpItem;

  for(iter = 0; iter < [self count]; iter++) {
    tmpItem = [self itemAtIndex:iter];
    if([tmpItem respondsToSelector:@selector(toRubyWithSymbolicKeys)]) {
      rb_ary_store(rb_returnArray, iter, [tmpItem toRubyWithSymbolicKeys]);
    }
    else if([tmpItem respondsToSelector:@selector(toRuby)]) {
      rb_ary_store(rb_returnArray, iter, [tmpItem toRuby]);
    }
    else
      rb_ary_store(rb_returnArray, iter, Qnil);
  }
  return rb_returnArray;
}


@end
