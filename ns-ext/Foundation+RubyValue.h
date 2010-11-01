
#import <Foundation/Foundation.h>
#import "ruby.h"

/**
 * The NSArray (RubyValue) extension allows for the simple translation of the
 *  NSArray object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface NSArray (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;

@end


/**
 * The NSDataArray (RubyValue) extension allows for the simple translation of the
 *  NSDataArray object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface NSMutableSet (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;
- (VALUE)toRubyWithSymbolicKeys;

@end


/**
 * The NSDictionary (RubyValue) extension allows for the simple translation of the
 *  NSDictionary object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface NSDictionary (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;
- (VALUE)toRubyWithSymbolicKeys;

@end


/**
 * The NSMutableArray (RubyValue) extension allows for the simple translation of the
 *  NSMutableArray object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface NSMutableArray (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;
- (VALUE)toRubyWithSymbolicKeys;

@end


/**
 * The NSNumber (RubyValue) extension allows for the simple translation of the
 *  NSNumber object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface NSNumber (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;

@end


/**
 * The NSString (RubyValue) extension allows for the simple translation of the
 *  NSString object into a Native Ruby Object (Specifically, for the MRI)
 */
@interface NSString (RubyValue)

/**
 * return The object in a Ruby-friendly form
 */
- (VALUE)toRuby;
- (VALUE)toRubySymbol;

@end
