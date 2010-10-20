#import <ObjFW/OFDataArray.h>
#import "ruby.h"

/**
 * The OFDataArray (Ruby) extension allows for the simple translation of the
 *  OFDataArray object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFDataArray (Ruby)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;
- (VALUE)toRubyWithSymbolicKeys;

@end
