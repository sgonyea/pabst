#import <ObjFW/OFDictionary.h>
#import "ruby.h"

/**
 * The OFDictionary (Ruby) extension allows for the simple translation of the
 *  OFDictionary object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFDictionary (Ruby)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;

@end
