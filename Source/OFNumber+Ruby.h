#import <ObjFW/OFNumber.h>
#import "ruby.h"

/**
 * The OFNumber (Ruby) extension allows for the simple translation of the
 *  OFNumber object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFNumber (Ruby)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;

@end
