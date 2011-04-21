
#import <ObjFW/ObjFW.h>
#import <ObjFW/OFDictionary.h>
#import "ruby.h"

/**
 * The OFArray (RubyValue) extension allows for the simple translation of the
 *  OFArray object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFArray (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;

@end


/**
 * The OFDataArray (RubyValue) extension allows for the simple translation of the
 *  OFDataArray object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFDataArray (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;
- (VALUE)toRubyWithSymbolicKeys;

@end


/**
 * The OFDictionary (RubyValue) extension allows for the simple translation of the
 *  OFDictionary object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFDictionary (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;
- (VALUE)toRubyWithSymbolicKeys;

@end


/**
 * The OFList (RubyValue) extension allows for the simple translation of the
 *  OFList object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFList (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;

@end


/**
 * The OFMutableArray (RubyValue) extension allows for the simple translation of the
 *  OFMutableArray object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFMutableArray (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;
- (VALUE)toRubyWithSymbolicKeys;

@end


/**
 * The OFNumber (RubyValue) extension allows for the simple translation of the
 *  OFNumber object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFNumber (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;

@end


/**
 * The OFString (RubyValue) extension allows for the simple translation of the
 *  OFString object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface OFString (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;
- (VALUE)toRubySymbol;

@end
