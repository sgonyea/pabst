
#import "OFArray+Ruby.h"

@implementation OFArray (Ruby)

- (VALUE)toRuby {
  return [array toRuby];
}
@end
