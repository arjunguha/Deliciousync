#import "Sync.h"
#import "DeliciousPost.h"

@implementation Sync

- (id)initFromDictionary:(NSDictionary *)dict
            syncDescPath:(NSString *)syncDescPath
        clientIdentifier:(NSString *)clientId
                    conn:(DeliciousConnection *)conn 
              destFolder:(NSString *)dest {
  safari = [[SafariSync alloc] initWithDictionary:[dict valueForKey:@"Safari"]
                                 clientIdentifier:clientId
                              descriptionFilePath:syncDescPath];
  delicious = [[DeliciousSync alloc] initFromDictionary:[dict valueForKey:@"Delicious"]
                                             connection:conn];
  destFolder = dest;
  return self;
}

- (NSDictionary *)toDictionary {
  return [NSDictionary dictionaryWithObjectsAndKeys:
          [safari toDictionary], @"Safari",
          [delicious toDictionary], @"Delicious",
          nil];
}


- (SafariUpdateRecord *)updateSafari {
  
  NSMutableSet *remBookmarks = [[NSMutableSet alloc] init];
  NSMutableDictionary *updBookmarks = [[NSMutableDictionary alloc] init];
  
  NSMutableSet *bookmarkHashes = [[NSMutableSet alloc] init];
    
  // Scan Safari bookmarks.  Check that all bookmarks have corresponding posts.  Delete if a post does not exist.
  for (SafariBookmark *bookmark in [safari allBookmarks]) {
    NSString *urlHash = [DeliciousPost md5:bookmark.href];
    [bookmarkHashes addObject:urlHash]; // for the next step
    if ([delicious postByHash:urlHash] == nil) {
      [remBookmarks addObject:bookmark.uuid];
      [safari removeBookmarkBySyncId:bookmark.uuid];
    }
  }
  
  // Scan Delicious posts.  If a post does not have a corresponding bookmark, create one.
  for (DeliciousPost *post in [delicious allPosts]) {
    if ([bookmarkHashes containsObject:post.hash] == NO) {      
      NSDictionary *syncRecord = [NSDictionary dictionaryWithObjectsAndKeys:
                                  EntityBookmark, ISyncRecordEntityNameKey,
                                  post.description, @"name",
                                  [NSURL URLWithString:post.href], @"url",
                                  destFolder == nil ? [NSArray array] : [NSArray arrayWithObject:destFolder], @"parent",
                                  nil];
      
      CFUUIDRef uuid = CFUUIDCreate(NULL);
      CFStringRef syncId_ = CFUUIDCreateString(NULL, uuid);
      CFRelease(uuid);
      
      NSString *syncId = [NSString stringWithString:(NSString *)syncId_];
      CFRelease(syncId_);
            
      SafariBookmark *bookmark = [[SafariBookmark alloc] initFromSyncRecord:syncRecord identifier:syncId];
      
      [safari addBookmark:bookmark];
      [updBookmarks setValue:syncRecord forKey:syncId];
    }
  }
  
  return [[SafariUpdateRecord alloc] initWithBookmarks:updBookmarks
                                               folders:[NSDictionary dictionary] 
                                      removedBookmarks:[remBookmarks allObjects]
                                        removedFolders:[NSArray array]];
}

- (void)updateDelicious:(NSArray **)removedUrls modified:(NSArray **)modifiedPosts {
  
  NSMutableSet *delBookmarks = [[NSMutableSet alloc] init];
  NSMutableArray *updBookmarks = [NSMutableArray array];
  
  NSMutableSet *safariHashes = [[NSMutableSet alloc] init];
  
  
  // Scan Safari bookmarks. If a bookmark does not have a corresponding post, create one. In addition, build a set
  // containing all URLs in Safari, for the next step.
  for (SafariBookmark *bookmark in [safari allBookmarks]) {
    NSString *urlHash = [DeliciousPost md5:bookmark.href];
    
    [safariHashes addObject:urlHash];
    
    if ([delicious postByHash:urlHash] == nil) {
      DeliciousPost *newPost = [[DeliciousPost alloc] initWithUrl:bookmark.href
                                                      description:bookmark.name
                                                             meta:@""
                                                             tags:[NSArray array]];
      [updBookmarks addObject:newPost];
      [delicious addPost:newPost];
    }
  } 
  
  // Scan Delicious posts. If a post does not have a corresponding URL in Safari, delete it.
  for (DeliciousPost *post in [delicious allPosts]) {
    if ([safariHashes containsObject:post.hash] == NO) {
      [delBookmarks addObject:post.href];
      [delicious removePostByHash:post.hash];
    }
  }
  
  *removedUrls = [delBookmarks allObjects];
  *modifiedPosts = updBookmarks;  
}


- (NSString *)destinationFolder {
  return destFolder;
}

- (void)setDestinationFolder:(NSString *)dest {
  destFolder = dest;
}

- (SafariSync *)safari {
  return safari;
}

- (DeliciousSync *)delicious {
  return delicious;
}

- (void)setSafari:(SafariSync *)newSafari {
  safari = newSafari;
}

- (void)setDelicious:(DeliciousSync *)newDelicious {
  delicious = newDelicious;
}

@end
