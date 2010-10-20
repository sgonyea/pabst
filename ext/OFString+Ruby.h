#import <ObjFW/OFString.h>
#import "ruby.h"

/**
 * The OFString (Ruby) extension allows for the simple translation of the
 *  OFString object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFString (Ruby)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;
- (VALUE)toRubySymbol;

@end
