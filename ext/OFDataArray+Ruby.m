
#import "OFDataArray+Ruby.h"
#import "ObjFW+Ruby.h"

@implementation OFDataArray (Ruby)

- (VALUE)toRuby {
  VALUE rb_returnArray = rb_ary_new2([self count]);
  size_t iter;

  for(iter = 0; iter < [self count]; iter++) {
    VALUE rb_object;

    rb_object = [[self itemAtIndex:iter] toRuby];

    if (rb_object) {
      rb_ary_store(rb_returnArray, iter, rb_object);
    } else {
      rb_ary_store(rb_returnArray, iter, Qnil);
    }
  }

  return rb_returnArray;
}

- (VALUE)toRubyWithSymbolicKeys {
  VALUE rb_returnArray = rb_ary_new2([self count]);
  size_t iter;

  for(iter = 0; iter < [self count]; iter++) {
    VALUE rb_object;

    if([self respondsToSelector:@selector(toRubyWithSymbolicKeys)])
      rb_object = [[self itemAtIndex:iter] toRubyWithSymbolicKeys];
    else
      rb_object = [[self itemAtIndex:iter] toRuby];

    if (rb_object) {
      rb_ary_store(rb_returnArray, iter, rb_object);
    } else {
      rb_ary_store(rb_returnArray, iter, Qnil);
    }
  }

  return rb_returnArray;
}


@end
