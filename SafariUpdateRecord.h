#import <Cocoa/Cocoa.h>

// This is equivalent to the one-line ML type: NSArray * NSArray * NSDictionary * NSDictionary
@interface SafariUpdateRecord : NSObject {
 @private
  NSArray *bookmarksToDelete;
  NSArray *foldersToDelete;
  NSDictionary *bookmarksToPush;
  NSDictionary *foldersToPush;
}

- (id)init;

-(id)initWithBookmarks:(NSDictionary *)bookmarks 
               folders:(NSDictionary *)folders
      removedBookmarks:(NSArray *)removedBookmarks
        removedFolders:(NSArray *)removedFolders;

@property (readonly) NSArray *bookmarksToDelete;
@property (readonly) NSArray *foldersToDelete;
@property (readonly) NSDictionary *bookmarksToPush;
@property (readonly) NSDictionary *foldersToPush;

@end
