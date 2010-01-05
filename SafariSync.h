#import <Cocoa/Cocoa.h>
#import <SyncServices/SyncServices.h>
#import "SafariUpdateRecord.h"
#import "SafariBookmark.h"
#import "SafariFolder.h"

@protocol SafariTrickleSyncing

- (SafariUpdateRecord *)syncAboutToStart:(NSArray *)entityNames;

- (BOOL)syncAboutToCommit;

@end

@interface SafariSync : NSObject <NSCopying> {
  
  NSString *descriptionFilePath;
  NSString *clientIdentifier;

  // Dictionaries keyed by syncId strings.
  NSMutableDictionary *allBookmarks;
  NSMutableDictionary *allFolders;
  
  id <SafariTrickleSyncing> trickleSyncDelegate;
    
  BOOL pullTheTruth;
}

- (id)initWithDictionary:(NSDictionary *)dict 
        clientIdentifier:(NSString *)clientIdentifier
     descriptionFilePath:(NSString *)path;

- (void)addBookmark:(SafariBookmark *)bookmark;
- (void)removeBookmarkBySyncId:(NSString *)syncId;
- (NSArray *)allBookmarks;
- (SafariBookmark *)bookmarkBySyncId:(NSString *)syncId;

- (void)registerClient;
- (void)resetData;

- (void)sync:(SafariUpdateRecord *)updates precommit:(BOOL (^)())precommitBlock;

- (void)trickleSync:(id<SafariTrickleSyncing>)delegate;

- (NSDictionary *)toDictionary;

- (NSMutableDictionary *)folders;

- (id)copyWithZone:(NSZone *)zone;

@end

