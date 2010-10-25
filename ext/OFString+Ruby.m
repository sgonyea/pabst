
#import "OFString+Ruby.h"
#import "ObjFW+Ruby.h"

@implementation OFString (Ruby)
- (VALUE)toRuby {
  return rb_str_new2([self cString]);
}

- (VALUE)toRubySymbol {
  return ID2SYM(rb_intern([self cString]));
}
@end
