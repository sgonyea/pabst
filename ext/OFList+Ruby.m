
#import "OFList+Ruby.h"
#import "ObjFW+Ruby.h"

@implementation OFList (Ruby)

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
