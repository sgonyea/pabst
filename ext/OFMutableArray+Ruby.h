#import <ObjFW/OFMutableArray.h>
#import "ruby.h"

/**
 * The OFMutableArray (Ruby) extension allows for the simple translation of the
 *  OFMutableArray object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFMutableArray (Ruby)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;
- (VALUE)toRubyWithSymbolicKeys;

@end
