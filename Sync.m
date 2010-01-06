#import "Sync.h"
#import "DeliciousPost.h"
#import "MultiDictionary.h"

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
  
  MultiDictionary *bookmarksByHash = [[MultiDictionary alloc] init];
  MultiDictionary *namesByHash = [[MultiDictionary alloc] init];
    
  // Scan Safari bookmarks.  Check that all bookmarks have corresponding posts.  Delete if a post does not exist.
  for (SafariBookmark *bookmark in [safari allBookmarks]) {    
    
    NSString *urlHash = [DeliciousPost md5:bookmark.href];
    
    // for the next step
    [bookmarksByHash addObject:bookmark forKey:urlHash]; 
    [namesByHash addObject:bookmark.name forKey:urlHash];
    
    if ([delicious postByHash:urlHash] == nil) {
      [remBookmarks addObject:bookmark.uuid];
      [safari removeBookmarkBySyncId:bookmark.uuid];
    }
  }
  
  // Scan Delicious posts.  If a post does not have a corresponding bookmark, create one.
  for (DeliciousPost *post in [delicious allPosts]) {
    
    NSSet *relatedNames = [bookmarksByHash objectsForKey:post.hash];
    
    if ([relatedNames count] == 0) {
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
    else {
      if ([relatedNames count] > 1 || [[[relatedNames anyObject] name] isEqualToString:post.description] == NO) {
        // Rename all related bookmarks
        for (SafariBookmark *bookmark in [bookmarksByHash objectsForKey:post.hash]) {
         SafariBookmark *renamedBookmark = [[SafariBookmark alloc] initWithSyncId:bookmark.uuid
                                                                             name:post.description 
                                                                              url:bookmark.url
                                                                           parent:bookmark.parent];
          
          [safari addBookmark:renamedBookmark];
          [updBookmarks setObject:[renamedBookmark toSyncRecord] forKey:bookmark.uuid];
        }
      }
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
  
  MultiDictionary *namesByUrl = [[MultiDictionary alloc] init];
  
  
  // Scan Safari bookmarks. If a bookmark does not have a corresponding post, create one.
  for (SafariBookmark *bookmark in [safari allBookmarks]) {
    NSString *urlHash = [DeliciousPost md5:bookmark.href];
    
    [namesByUrl addObject:bookmark.name forKey:bookmark.href]; // to compute renames (later)
    
    
    
    if ([delicious postByHash:urlHash] == nil) {
      DeliciousPost *newPost = [[DeliciousPost alloc] initWithUrl:bookmark.href
                                                      description:bookmark.name
                                                             meta:@""
                                                             tags:[NSArray array]];
      [updBookmarks addObject:newPost];
      [delicious addPost:newPost];
    }
  }
                                 
  for (DeliciousPost *post in [delicious allPosts]) {
    NSSet *names = [namesByUrl objectsForKey:post.href];
    int numNames = [names count];
    
    if (numNames == 0) {
      // No corresponding Safari URL, so delete it.
      [delBookmarks addObject:post.href];
      [delicious removePostByHash:post.hash];
    }
    else {
      // We just pulled from Safari, so Safari's name is the truth.
      NSString *name = [names anyObject];
      if ([post.description isEqualToString:name] == NO || numNames > 1) {
        
        if (numNames > 0 && [post.description isEqualToString:name]) {
          // We picked the old name, make certain we pick a new name.
          NSMutableSet *newNames = [names mutableCopy];
          [newNames removeObject:post.description];
          name = [names anyObject];
        }
        
        DeliciousPost *newPost = [[DeliciousPost alloc] initWithUrl:post.href
                                                        description:name
                                                               meta:@""
                                                               tags:[NSArray array]];
        [updBookmarks addObject:newPost];
        [delicious addPost:newPost];
        if (numNames > 1) {
          NSLog(@"picking name %@ (of %d names) for %@", name, numNames, post.href);
        }
      }
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
