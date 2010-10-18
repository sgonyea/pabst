#import <ObjFW/OFArray.h>
#import "ruby.h"

/**
 * The OFArray (Ruby) extension allows for the simple translation of the
 *  OFArray object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFArray (Ruby)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;

@end
