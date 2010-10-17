
#import <ObjFW/OFList.h>
#import "ruby.h"

/**
 * The OFList (Ruby) extension allows for the simple translation of the
 *  OFList object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFList (Ruby)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;

@end
