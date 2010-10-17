
#import "OFMutableArray+Ruby.h"

@implementation OFMutableArray (Ruby)

- (VALUE)toRuby {
  return [array toRuby];
}
@end
