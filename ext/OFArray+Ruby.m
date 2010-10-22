
#import "OFArray+Ruby.h"
#import "ObjFW+Ruby.h"

@implementation OFArray (Ruby)

- (VALUE)toRuby {
  VALUE rb_returnArray = rb_ary_new2([self count]);
  size_t iter;

  for(iter = 0; iter < [self count]; iter++) {
    id tempObj = [self objectAtIndex:iter];

    if([tempObj respondsToSelector:@selector(toRuby)])
	    rb_ary_store(rb_returnArray, iter, [tempObj toRuby]);
    else
      rb_ary_store(rb_returnArray, iter, Qnil);
  }

  return rb_returnArray;
}
@end
