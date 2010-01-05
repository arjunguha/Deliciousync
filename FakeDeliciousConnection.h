// FakeDeliciousConnection exposes the same API (requestPath) as DeliciousConnection. However, the bookmark data is
// stored in a local file. requestPath only implements the subset of the Delicious API that is used by DeliciousSync.
#import <Cocoa/Cocoa.h>


@interface FakeDeliciousConnection : NSObject {
  
 @private  
  NSString *cachePath;
  NSDate *lastUpdateTime;
  NSThread *cachePoll;
  
  // DeliciousPost objects, keyed by url hashes.
  NSMutableDictionary *posts;
}

- (id)initWithPath:(NSString *)path;

-(void)load;
-(void)save;


@end
