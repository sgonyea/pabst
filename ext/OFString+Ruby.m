
#import "OFString+Ruby.h"
#import "ObjFW+Ruby.h"

@implementation OFString (Ruby)

- (VALUE)toRuby {

  /* @TODO: Verify the encoding and set it to the rb_str object, if not UTF8
  if (isUTF8) {
  } else {
  }
  */
  return rb_str_new(string, length);
}

- (VALUE)toRubySymbol {
  return ID2SYM(rb_intern([self cString]));
}

@end
