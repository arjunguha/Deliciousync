#import "SafariUpdateRecord.h"

@implementation SafariUpdateRecord

@synthesize bookmarksToDelete, foldersToDelete, bookmarksToPush, foldersToPush;

- (id)init {
  bookmarksToPush = nil;
  foldersToPush = nil;
  bookmarksToDelete = nil;
  foldersToDelete = nil;
  return self;
}

-(id)initWithBookmarks:(NSDictionary *)bookmarks 
               folders:(NSDictionary *)folders
      removedBookmarks:(NSArray *)removedBookmarks
        removedFolders:(NSArray *)removedFolders {
  bookmarksToPush = bookmarks;
  foldersToPush = folders;
  bookmarksToDelete = removedBookmarks;
  foldersToDelete = removedFolders;
  return self;
}

@end
