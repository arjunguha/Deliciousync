#import "MultiDictionary.h"


@implementation MultiDictionary

- (id)init {
  
  dict = [NSMutableDictionary dictionary];
  return self;
}

- (NSSet *)objectsForKey:(id)key {
  
  NSMutableSet *objs = [dict objectForKey:key];
  return objs == nil ? [NSSet set] : objs;
}

- (void)addObject:(id)obj forKey:(id)key {
  
  NSMutableSet *set = [dict objectForKey:key];
  
  if (set == nil) {
    set = [NSMutableSet setWithObject:obj];
    [dict setObject:set forKey:key];
  }
  
  [set addObject:obj];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len {
  return [dict countByEnumeratingWithState:state objects:stackbuf count:len];
}
  



@end
