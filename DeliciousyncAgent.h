#import <Cocoa/Cocoa.h>
#import "LocalStorage.h"
#import "Sync.h"

@interface DeliciousyncAgent : NSObject {

  LocalStorage *storage;
  Sync *sync;
  NSString *destFolder;
  NSString *deliciousUsername;
  NSString *deliciousPassword;
  
}

+ (void)setDestinationFolder:(NSString *)dest;
+ (void)registerClient;
+ (void)updateDestFolder:(NSString *)dest username:(NSString *)username;

- (id)init;
- (void)sync;
- (void)refreshSync;
- (void)prefsAndFolders;

@end
