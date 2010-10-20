
#import "OFNumber+Ruby.h"
#import "ObjFW+Ruby.h"

@implementation OFNumber (Ruby)

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