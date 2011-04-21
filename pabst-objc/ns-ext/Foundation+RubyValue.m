
#import "Foundation+RubyValue.h"

@implementation NSArray (RubyValue)
- (VALUE)toRuby {
  VALUE rb_returnArray = rb_ary_new2([self count]);
  size_t iter;
  
  for(iter = 0; iter < [self count]; iter++) {
    id tempObj = [self objectAtIndex:iter];
    
    if([tempObj respondsToSelector:@selector(toRuby)])
      rb_ary_store(rb_returnArray, iter, [tempObj toRuby]);
    else
      rb_ary_store(rb_returnArray, iter, Qnil);
  }
  
  return rb_returnArray;
}
@end


@implementation NSMutableSet (RubyValue)
- (VALUE)toRuby {
  VALUE rb_returnArray = rb_ary_new2([self count]);
  size_t iter;
  id tmpItem;
  
  for(iter = 0; iter < [self count]; iter++) {
    tmpItem = [self itemAtIndex:iter];
    if([tmpItem respondsToSelector:@selector(toRuby)])
      rb_ary_store(rb_returnArray, iter, [tmpItem toRuby]);
    else
      rb_ary_store(rb_returnArray, iter, Qnil);
  }
  
  return rb_returnArray;
}

- (VALUE)toRubyWithSymbolicKeys {
  VALUE rb_returnArray = rb_ary_new2([self count]);
  size_t iter;
  id tmpItem;
  
  for(iter = 0; iter < [self count]; iter++) {
    tmpItem = [self itemAtIndex:iter];
    if([tmpItem respondsToSelector:@selector(toRubyWithSymbolicKeys)]) {
      rb_ary_store(rb_returnArray, iter, [tmpItem toRubyWithSymbolicKeys]);
    }
    else if([tmpItem respondsToSelector:@selector(toRuby)]) {
      rb_ary_store(rb_returnArray, iter, [tmpItem toRuby]);
    }
    else
      rb_ary_store(rb_returnArray, iter, Qnil);
  }
  return rb_returnArray;
}
@end


@implementation NSDictionary (RubyValue)
- (VALUE)toRuby {
  VALUE rb_returnHash = rb_hash_new();

#ifdef NS_HAVE_BLOCKS
  [self enumerateKeysAndObjectsUsingBlock:
   ^(id key, id obj, BOOL *stop) {
     VALUE keyValue;
     VALUE objValue;
     
     if([key respondsToSelector:@selector(toRuby)])
       keyValue = [key toRuby];
     else
       keyValue = Qnil;
     
     if([obj respondsToSelector:@selector(toRuby)])
       objValue = [obj toRuby];
     else
       objValue = Qnil;
     
     rb_hash_aset(rb_returnHash, keyValue, objValue);
   }];
#else
  NSEnumerator *keyEnum = [self keyEnumerator];
  id     dictKey,  dictObj;
  VALUE keyValue,  objValue;

  while(dictKey = [keyEnum nextObject]) {
    dictObj = [self objectForKey:dictKey];

    if([dictKey respondsToSelector:@selector(toRuby)])
      keyValue  =  [dictKey toRuby];
    else
      keyValue  = Qnil;
    
    if([dictObj respondsToSelector:@selector(toRuby)])
      objValue  =  [dictObj toRuby];
    else
      objValue  = Qnil;

    rb_hash_aset(rb_returnHash, keyValue, objValue);
  }
#endif
  
  return rb_returnHash;
}

- (VALUE)toRubyWithSymbolicKeys {
  VALUE rb_returnHash = rb_hash_new();

#ifdef NS_HAVE_BLOCKS
  [self enumerateKeysAndObjectsUsingBlock:
   ^(id key, id obj, BOOL *stop) {
     VALUE objValue;
     VALUE keyValue;
     
     if([key respondsToSelector:@selector(toRubySymbol)])
       keyValue = [key toRubySymbol];
     else if([key respondsToSelector:@selector(toRuby)])
       keyValue = [key toRuby];
     else
       keyValue = Qnil;
     
     if([obj respondsToSelector:@selector(toRuby)])
       objValue = [obj toRuby];
     else
       objValue = Qnil;
     
     rb_hash_aset(rb_returnHash, keyValue, objValue);
   }];
#else
  NSEnumerator *keyEnum = [self keyEnumerator];
  id     dictKey,  dictObj;
  VALUE keyValue,  objValue;
  
  while(dictKey = [keyEnum nextObject]) {
    dictObj = [self objectForKey:dictKey];
    
    if([dictKey respondsToSelector:@selector(toRubySymbol)])
      keyValue = [dictKey toRubySymbol];
    else if([dictKey respondsToSelector:@selector(toRuby)])
      keyValue = [dictKey toRuby];
    else
      keyValue = Qnil;

    if([dictObj respondsToSelector:@selector(toRuby)])
      objValue  =  [dictObj toRuby];
    else
      objValue  = Qnil;
    
    rb_hash_aset(rb_returnHash, keyValue, objValue);
  }
#endif
  
  return rb_returnHash;
}
@end


@implementation NSMutableArray (RubyValue)
- (VALUE)toRuby {
  VALUE rb_returnArray = rb_ary_new2([self count]);
  size_t iter;
  id tmpObject;
  
  for(iter = 0; iter < [self count]; iter++) {
    tmpObject = [self objectAtIndex:iter];
    
    if([tmpObject respondsToSelector:@selector(toRuby)])
      rb_ary_store(rb_returnArray, iter, [tmpObject toRuby]);
    else
      rb_ary_store(rb_returnArray, iter, Qnil);
  }
  
  return rb_returnArray;
}

- (VALUE)toRubyWithSymbolicKeys {
  VALUE rb_returnArray = rb_ary_new2([self count]);
  size_t iter;
  id tmpObject;
  
  for(iter = 0; iter < [self count]; iter++) {
    tmpObject = [self objectAtIndex:iter];
    
    if([tmpObject respondsToSelector:@selector(toRubyWithSymbolicKeys)])
      rb_ary_store(rb_returnArray, iter, [tmpObject toRubyWithSymbolicKeys]);
    else if([tmpObject respondsToSelector:@selector(toRuby)])
      rb_ary_store(rb_returnArray, iter, [tmpObject toRuby]);
    else
      rb_ary_store(rb_returnArray, iter, Qnil);
  }
  
  return rb_returnArray;
}
@end


@implementation NSNumber (RubyValue)
- (VALUE)toRuby {
  const char *_type = [self objCType];

  if(strcmp(_type, @encode(char)))            return CHR2FIX([self charValue]);
  if(strcmp(_type, @encode(unsigned char)))   return CHR2FIX([self charValue]);
  if(strcmp(_type, @encode(short)))           return INT2FIX([self intValue]);
  if(strcmp(_type, @encode(long)))            return INT2FIX([self intValue]);
  if(strcmp(_type, @encode(int)))             return INT2FIX([self intValue]);
  if(strcmp(_type, @encode(unsigned short)))  return UINT2NUM([self intValue]);
  if(strcmp(_type, @encode(unsigned long)))   return UINT2NUM([self intValue]);
  if(strcmp(_type, @encode(unsigned int)))    return UINT2NUM([self intValue]);
  if(strcmp(_type, @encode(float)))           return rb_float_new([self floatValue]);
  if(strcmp(_type, @encode(double)))          return rb_float_new([self floatValue]);

  return Qnil;
}
@end


@implementation NSString (RubyValue)
- (VALUE)toRuby {
  return rb_str_new2([self cString]);
}

- (VALUE)toRubySymbol {
  return ID2SYM(rb_intern([self cString]));
}
@end

