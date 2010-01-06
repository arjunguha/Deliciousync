#import <Cocoa/Cocoa.h>


@interface MultiDictionary : NSObject <NSFastEnumeration> {

  NSMutableDictionary *dict;
}

- (id)init;

// Adds obj to the set of objects associated with key.
- (void)addObject:(id)obj forKey:(id)key;

- (NSSet *)objectsForKey:(id)key;


- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(id *)stackbuf count:(NSUInteger)len;

@end
