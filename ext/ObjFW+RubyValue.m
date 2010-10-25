
#import "ObjFW+RubyValue.h"

@implementation OFArray (RubyValue)
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


@implementation OFDataArray (RubyValue)
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


@implementation OFDictionary (RubyValue)
- (VALUE)toRuby {
  VALUE rb_returnHash = rb_hash_new();
  
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
  
  return rb_returnHash;
}

- (VALUE)toRubyWithSymbolicKeys {
  VALUE rb_returnHash = rb_hash_new();
  
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
  
  return rb_returnHash;
}
@end


@implementation OFList (RubyValue)
- (VALUE)toRuby {
  VALUE rb_returnArray = rb_ary_new2(count);
  size_t iter;
  of_list_object_t *listObj;
  
  for(iter = 0, listObj = [self firstListObject]; iter < count; iter++, listObj = listObj->next) {
    VALUE rb_listObject;
    
    rb_listObject = [listObj->object toRuby];
    if (rb_listObject) {
      rb_ary_store(rb_returnArray, iter, rb_listObject);
    } else {
      rb_ary_store(rb_returnArray, iter, Qnil);
    }
  }
  
  return rb_returnArray;
}
@end


@implementation OFMutableArray (RubyValue)
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


@implementation OFNumber (RubyValue)
- (VALUE)toRuby {
  VALUE rb_returnNumber;
  
  switch (type) {
    case OF_NUMBER_CHAR:
      rb_returnNumber = CHR2FIX(value.char_);
      break;
    case OF_NUMBER_UCHAR:
      rb_returnNumber = CHR2FIX(value.uchar);
      break;
    case OF_NUMBER_SHORT:
      rb_returnNumber = INT2FIX(value.short_);
      break;
    case OF_NUMBER_INT:
      rb_returnNumber = INT2FIX(value.int_);
      break;
    case OF_NUMBER_LONG:
      rb_returnNumber = INT2FIX(value.long_);
      break;
    case OF_NUMBER_USHORT:
      rb_returnNumber = INT2FIX(value.ushort);
      break;
    case OF_NUMBER_UINT:
      rb_returnNumber = INT2NUM(value.uint);
      break;
    case OF_NUMBER_ULONG:
      rb_returnNumber = INT2FIX(value.ulong);
      break;
    case OF_NUMBER_INT8:
      rb_returnNumber = INT2FIX(value.int8);
      break;
    case OF_NUMBER_INT16:
      rb_returnNumber = INT2FIX(value.int16);
      break;
    case OF_NUMBER_INT32:
      rb_returnNumber = INT2FIX(value.int32);
      break;
    case OF_NUMBER_INT64:
      rb_returnNumber = INT2NUM(value.int64);
      break;
    case OF_NUMBER_UINT8:
      rb_returnNumber = INT2FIX(value.uint8);
      break;
    case OF_NUMBER_UINT16:
      rb_returnNumber = INT2FIX(value.uint16);
      break;
    case OF_NUMBER_UINT32:
      rb_returnNumber = INT2FIX(value.uint32);
      break;
    case OF_NUMBER_UINT64:
      rb_returnNumber = INT2NUM(value.uint64);
      break;
    case OF_NUMBER_SIZE:
      rb_returnNumber = INT2FIX(value.size);
      break;
    case OF_NUMBER_SSIZE:
      rb_returnNumber = INT2FIX(value.ssize);
      break;
    case OF_NUMBER_INTMAX:
      rb_returnNumber = INT2FIX(value.intmax);
      break;
    case OF_NUMBER_UINTMAX:
      rb_returnNumber = INT2NUM(value.uintmax);
      break;
    case OF_NUMBER_PTRDIFF:
      rb_returnNumber = INT2NUM(value.ptrdiff);
      break;
    case OF_NUMBER_INTPTR:
      rb_returnNumber = INT2NUM(value.intptr);
      break;
    case OF_NUMBER_UINTPTR:
      rb_returnNumber = INT2NUM(value.uintptr);
      break;
    case OF_NUMBER_FLOAT:
      rb_returnNumber = rb_float_new(value.float_);
      break;
    case OF_NUMBER_DOUBLE:
      rb_returnNumber = rb_float_new(value.double_);
      break;
    default:
      rb_returnNumber = Qnil;
      break;
  }
  
  return rb_returnNumber;
}
@end


@implementation OFString (RubyValue)
- (VALUE)toRuby {
  return rb_str_new2([self cString]);
}

- (VALUE)toRubySymbol {
  return ID2SYM(rb_intern([self cString]));
}
@end

