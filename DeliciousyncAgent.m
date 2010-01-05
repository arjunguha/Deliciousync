#import "DeliciousyncAgent.h"
#import "Common.h"
#ifdef LOCAL_DEBUG
#import "FakeDeliciousConnection.h"
#endif


@implementation DeliciousyncAgent

+ (LocalStorage *)initStorage {
  return [[LocalStorage alloc] initWithPathInApplicationSupport:@"posts.plist"
                                                    application:@"Deliciousync"];
}

+ (void)registerClient {
  ISyncManager *syncManager = [ISyncManager sharedManager];
  [syncManager registerClientWithIdentifier:@"DeliciousyncAgent"
                        descriptionFilePath:pathInAppSupport(@"DeliciousyncAgentClientDescription")];  
}

   
+ (void)setDestinationFolder:(NSString *)dest {
  
  LocalStorage *storage = [DeliciousyncAgent initStorage];
  NSMutableDictionary *dict = [[storage read] mutableCopy];
  [dict setValue:dest forKey:@"destFolder"];
  [storage write:dict];  
}
               
+ (void)updateDestFolder:(NSString *)dest username:(NSString *)username {
  
  LocalStorage *storage = [DeliciousyncAgent initStorage];
  NSMutableDictionary *dict = [[storage read] mutableCopy];
  [dict setValue:username forKey:@"deliciousUsername"];
  [dict setValue:dest forKey:@"destFolder"];
  [storage write:dict];  
}

- (void)saveToStorage {
  [storage write:[NSDictionary dictionaryWithObjectsAndKeys:
                  [sync toDictionary], @"sync",
                  deliciousUsername, @"deliciousUsername",
                  destFolder, @"destFolder",
                  nil]];
}

- (void)pullFromDelicious {
  [[sync delicious] pullFromDelicious];
}

- (void)pushToDelicious {
  
  NSArray *removed = nil;
  NSArray *modified = nil;
  [sync updateDelicious:&removed modified:&modified];
  [[sync delicious] pushToDelicious:removed modified:modified];
  [self saveToStorage];
}

- (void)syncWithSafari {
  
  [[sync safari] sync:[sync updateSafari]
            precommit:^{ 
              [self saveToStorage];
              return YES; 
            }];
}

- (void)sync {
  // methods below handle saving
  [self pullFromDelicious];
  [self syncWithSafari];
  [self pushToDelicious];
}

- (void)refreshSync {
  [[sync safari] resetData];
  [self syncWithSafari];
}

- (id)init {
  
  storage = [DeliciousyncAgent initStorage];
  NSDictionary *dict = [storage read];
  destFolder = [dict valueForKey:@"destFolder"];
  deliciousUsername = [dict valueForKey:@"deliciousUsername"];
  deliciousPassword = [Common getPasswordForUsername:deliciousUsername];
  
#ifdef LOCAL_DEBUG
  id conn = [[FakeDeliciousConnection alloc] initWithPath:@"/Users/arjun/Desktop/fake.plist"];
#else
  id conn = [[DeliciousConnection alloc] initWithUsername:deliciousUsername 
                                                 Password:deliciousPassword];
#endif
  
  sync = [[Sync alloc] initFromDictionary:[dict valueForKey:@"sync"]
                             syncDescPath:pathInAppSupport(@"DeliciousyncAgentClientDescription.plist")
                         clientIdentifier:@"DeliciousyncAgent"
                                     conn:conn 
                               destFolder:destFolder];
  
  return self;
}

// Prints a dictionary of sync records for all folders.
- (void)prefsAndFolders {
  
  [[sync safari] sync:[[SafariUpdateRecord alloc] init]
            precommit:^{
              [self saveToStorage];
              return YES;
            }];
  
  NSDictionary *folders = [[sync safari] folders];
  
  NSMutableDictionary *foldersDict = [NSMutableDictionary dictionaryWithCapacity:[folders count]];
  for (NSString *syncId in folders) {
    [foldersDict setValue:[[folders valueForKey:syncId] toSyncRecord]
                   forKey:syncId];
  }
  
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        foldersDict, @"folders",
                        destFolder == nil ? [NSArray array] : [NSArray arrayWithObject:destFolder], 
                        @"destinationFolder",
                        deliciousUsername == nil ? [NSArray array] : [NSArray arrayWithObject:deliciousUsername],
                        @"deliciousUsername",
                        nil];
  
  NSError *err = nil;  
  NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict 
                                                            format:NSPropertyListXMLFormat_v1_0
                                                           options:0
                                                             error:&err];
  
  NSFileHandle *stdout = [NSFileHandle fileHandleWithStandardOutput];
  [stdout writeData:data];  
}


@end
