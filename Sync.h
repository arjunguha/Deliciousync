#import <Cocoa/Cocoa.h>
#import "SafariSync.h"
#import "DeliciousSync.h"



@interface Sync : NSObject {
 @private
  // Newly created Delicious bookmarks go here
  NSString *destFolder;
  SafariSync *safari;
  DeliciousSync *delicious;
}

- (id)initFromDictionary:(NSDictionary *)dict 
            syncDescPath:(NSString *)syncDescPath
        clientIdentifier:(NSString *)clientId
                    conn:(DeliciousConnection *)conn
              destFolder:(NSString *)destFolder;
- (NSDictionary *)toDictionary;


- (SafariUpdateRecord *)updateSafari;
- (void)updateDelicious:(NSArray **)removedUrls modified:(NSArray **)modifiedPosts;

- (SafariSync *)safari;
- (DeliciousSync *)delicious;

- (void)setSafari:(SafariSync *)newSafari;
- (void)setDelicious:(DeliciousSync *)newDelicious;


- (NSString *)destinationFolder;
- (void)setDestinationFolder:(NSString *)dest;

@end
