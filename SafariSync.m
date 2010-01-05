#import "SafariSync.h"


@implementation SafariSync

- (id)initWithDictionary:(NSDictionary *)dict 
        clientIdentifier:(NSString *)clientId
     descriptionFilePath:(NSString *)path {

  clientIdentifier = clientId;
  descriptionFilePath = path;
  
  allBookmarks = [[NSMutableDictionary alloc] init];
  allFolders = [[NSMutableDictionary alloc] init];  
  pullTheTruth = NO;  
  
  NSDictionary *bookmarksDict = [dict objectForKey:@"bookmarks"];
  for (NSString *syncId in bookmarksDict) {
    [allBookmarks setValue:[[SafariBookmark alloc] initFromDictionary:[bookmarksDict objectForKey:syncId]]
                    forKey:syncId];
  }
  
  NSDictionary *foldersDict = [dict objectForKey:@"folders"];
  for (NSString *syncId in foldersDict) {
    [allFolders setValue:[[SafariFolder alloc] initFromDictionary:[foldersDict objectForKey:syncId]]
                  forKey:syncId];
  }
  
  return self;  
}

- (id)copyWithZone:(NSZone *)zone {

  SafariSync *newObj = [SafariSync allocWithZone:zone];
  newObj->allBookmarks = [allBookmarks mutableCopyWithZone:zone];
  newObj->allFolders = [allFolders mutableCopyWithZone:zone];
  newObj->pullTheTruth = NO;
  return newObj;
}
  
- (NSMutableDictionary *)folders {
  return allFolders;
}

- (void)addBookmark:(SafariBookmark *)bookmark {
  [allBookmarks setValue:bookmark forKey:bookmark.uuid];
}

- (void)removeBookmarkBySyncId:(NSString *)syncId {
  [allBookmarks removeObjectForKey:syncId];
}

- (NSArray *)allBookmarks {
  return [allBookmarks allValues];
}

- (SafariBookmark *)bookmarkBySyncId:(NSString *)syncId {
  return [allBookmarks valueForKey:syncId];
}

- (void)resetData {
  
  pullTheTruth = YES;
  [allBookmarks removeAllObjects];
  [allFolders removeAllObjects];
}

- (void)registerClient {
  ISyncManager *syncManager = [ISyncManager sharedManager];
  [syncManager registerClientWithIdentifier:clientIdentifier 
                        descriptionFilePath:descriptionFilePath];
}

- (ISyncClient *)getSyncClient {
  
  ISyncManager *syncManager = [ISyncManager sharedManager];
  ISyncClient *syncClient = [syncManager clientWithIdentifier:clientIdentifier];
  
  if (syncClient == nil) {
    syncClient = [syncManager registerClientWithIdentifier:clientIdentifier 
                                       descriptionFilePath:descriptionFilePath];
  }
  
  NSAssert(syncClient != nil, @"Failed to register as a Sync client.");
  
  return syncClient;
}

- (NSDictionary *)toDictionary {
  
  NSMutableDictionary *bookmarksDict = [[NSMutableDictionary alloc] init];
  for (NSString *syncId in allBookmarks) {
    [bookmarksDict setValue:[[allBookmarks objectForKey:syncId] toDictionary]
                     forKey:syncId];
  }
  
  NSMutableDictionary *foldersDict = [[NSMutableDictionary alloc] init];
  for (NSString *syncId in allFolders) {
    [foldersDict setValue:[[allFolders objectForKey:syncId] toDictionary]
                   forKey:syncId];
  }

  return [NSDictionary dictionaryWithObjectsAndKeys:
          bookmarksDict, @"bookmarks",
          foldersDict, @"folders",
          nil];
}

- (void)pushToSyncServices:(ISyncSession *)syncSession 
                entityName:(NSString *)entityName
                allRecords:(NSDictionary *)allRecords
                   removed:(NSArray *)removedSyncIds
                  modified:(NSDictionary *)syncChanges {
  
  NSLog(@"pushing %@ records", entityName);
  
  BOOL slow = [syncSession shouldPushAllRecordsForEntityName:entityName];
  BOOL fast = [syncSession shouldPushChangesForEntityName:entityName];
  
  if (slow) {
    for (NSString *syncId in allRecords) {
      id record = [[allRecords valueForKey:syncId] toSyncRecord];
      NSLog(@"Pushing %@: %@ = %@", entityName, syncId, record);
      [syncSession pushChangesFromRecord:record withIdentifier:syncId];
    } 
  }
  else if (fast) {
    for (NSString *syncId in removedSyncIds) {
      [syncSession deleteRecordWithIdentifier:syncId];
    }
    
    for (NSString *syncId in syncChanges) {
      NSDictionary *record = [syncChanges valueForKey: syncId];
      NSLog(@"Pushing %@: %@ = %@", entityName, syncId, record);
      [syncSession pushChangesFromRecord:record withIdentifier:syncId];
    } 
  }
  else {
    NSLog(@"pushToSyncServices: neither slow sync nor fast sync set!");
    return;
  }
}

- (void)pullBookmarksFromSyncServices:(ISyncSession *)syncSession {
  
  if ([syncSession shouldPullChangesForEntityName:EntityBookmark] == NO) {
    NSLog(@"Pull from Sync Services: instructed not to pull bookmarks.");
    return;
  }
  
  BOOL reset = [syncSession shouldReplaceAllRecordsOnClientForEntityName:EntityBookmark];
  
  if (![syncSession prepareToPullChangesForEntityNames:[NSArray arrayWithObject:EntityBookmark]
                                            beforeDate:[NSDate distantFuture]]) {
    NSLog(@"Pull from Sync Services: sync error");
    return;
  }
  
  if (pullTheTruth || reset) {
    NSLog(@"Pull from Sync Services: resetting client state");
    [allBookmarks removeAllObjects];
  }
  
  NSMutableArray *acceptedChanges = [[NSMutableArray alloc] init];
  
  for (ISyncChange *change in [syncSession changeEnumeratorForEntityNames:[NSArray arrayWithObject:EntityBookmark]]) {
    
    NSString *syncId = [change recordIdentifier];
    
    switch ([change type]) {
      case ISyncChangeTypeDelete:
        [allBookmarks removeObjectForKey:syncId];
        break;
      case ISyncChangeTypeAdd:
        [allBookmarks setValue:[[SafariBookmark alloc] initFromSyncRecord:[change record] identifier:syncId]
                        forKey:syncId];
        break;
      case ISyncChangeTypeModify:
        [allBookmarks setValue:[[allBookmarks objectForKey:syncId] updateWithSyncRecord:[change record]]
                        forKey:syncId];
        break;
    }
    [acceptedChanges addObject:syncId];
  }
  
  for (NSString *syncId in acceptedChanges) {
    [syncSession clientAcceptedChangesForRecordWithIdentifier:syncId formattedRecord:nil newRecordIdentifier:nil];
  }
}

- (void)pullFoldersFromSyncServices:(ISyncSession *)syncSession {
  
  if ([syncSession shouldPullChangesForEntityName:EntityFolder] == NO) {
    NSLog(@"Pull from Sync Services: instructed not to pull folders.");
    return;
  }
    
  BOOL reset = [syncSession shouldReplaceAllRecordsOnClientForEntityName:EntityFolder];
  
  if ([syncSession prepareToPullChangesForEntityNames:[NSArray arrayWithObject:EntityFolder]
                                           beforeDate:[NSDate distantFuture]]) {
    NSLog(@"Pulling folders: timeout waiting for Sync Services.");
    return;
  }
  
  if (pullTheTruth || reset) {
    NSLog(@"Pull from Sync Services: resetting client state");
    [allFolders removeAllObjects];
  }    
  
  NSMutableArray *acceptedChanges = [[NSMutableArray alloc] init];
  
  for (ISyncChange *change in [syncSession changeEnumeratorForEntityNames:[NSArray arrayWithObject:EntityFolder]]) {
    NSString *syncId = [change recordIdentifier];
    
    switch ([change type]) {
      case ISyncChangeTypeDelete:
        [allFolders removeObjectForKey:syncId];
        break;
      case ISyncChangeTypeAdd:
      case ISyncChangeTypeModify:
        [allFolders setValue:[[SafariFolder alloc] initFromSyncRecord:[change record] identifier:syncId]
                      forKey:syncId];
        break;
    }
    
    [acceptedChanges addObject:syncId];
  }
  
  for (NSString *syncId in acceptedChanges) {
    [syncSession clientAcceptedChangesForRecordWithIdentifier:syncId formattedRecord:nil newRecordIdentifier:nil];
  }
}

- (void)sync:(SafariUpdateRecord *)updates precommit:(BOOL (^)())precommitBlock {
    
  NSArray *entities = [NSArray arrayWithObjects:EntityBookmark, EntityFolder, nil];
  
  ISyncClient *syncClient = [self getSyncClient];
  ISyncSession *syncSession = [ISyncSession beginSessionWithClient:syncClient
                                                       entityNames:entities 
                                                        beforeDate:[NSDate distantFuture]];
  
  if (pullTheTruth) {
    NSLog(@"requesting all records from Sync Services");
    [syncSession clientDidResetEntityNames:entities];
  }
    
  [self pushToSyncServices:syncSession 
                entityName:EntityFolder 
                allRecords:allFolders
                   removed:updates.foldersToDelete
                  modified:updates.foldersToPush];
  
  [self pushToSyncServices:syncSession 
                entityName:EntityBookmark 
                allRecords:allBookmarks
                   removed:updates.bookmarksToDelete
                  modified:updates.bookmarksToPush];

  [self pullBookmarksFromSyncServices:syncSession];
  
  [self pullFoldersFromSyncServices:syncSession];
  
  pullTheTruth = NO;
  
  if (precommitBlock()) {
    [syncSession clientCommittedAcceptedChanges];
    [syncSession finishSyncing];
  }
  else {
    [syncSession cancelSyncing];
  }
}

- (void)trickleSync:(id<SafariTrickleSyncing>)del {
  
  trickleSyncDelegate = del;
    
  ISyncClient *client = [self getSyncClient];

  [client setShouldSynchronize:YES withClientsOfType:ISyncClientTypeApplication];
  [client setShouldSynchronize:YES withClientsOfType:ISyncClientTypeServer];
  [client setSyncAlertHandler:self selector:@selector(client:mightWantToSyncEntityNames:)];
}

- (void)client:(ISyncClient *)client mightWantToSyncEntityNames:(NSArray *)entityNames {
  
  SafariUpdateRecord *updates = [trickleSyncDelegate syncAboutToStart:entityNames];
  
  if (updates != nil) {
    [self sync:updates
     precommit:^{
       return [trickleSyncDelegate syncAboutToCommit];
     }];
  }
}

@end