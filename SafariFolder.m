#import "SafariFolder.h"
#import <SyncServices/SyncServices.h>

@implementation SafariFolder

@synthesize name, parent, children, syncId;

- (id)initWithSyncId:(NSString *)syncId_ name:(NSString *)name_ parent:(NSArray *)parent_ {
  
  syncId = syncId_;
  name = name_;
  parent = parent_;
  
  return self;
}

- (id)initFromDictionary:(NSDictionary *)dict {
  return [self initWithSyncId:[dict objectForKey:@"syncId"]
                         name:[dict objectForKey:@"name"] 
                       parent:[dict objectForKey:@"parent"]];
}

- (id)initFromSyncRecord:(NSDictionary *)record identifier:(NSString *)syncId_ {
  
  syncId = syncId_;
  name = [record objectForKey:@"name"];
  parent = [record objectForKey:@"parent"];
  return self;
}

- (NSDictionary *)toSyncRecord {
  return [NSDictionary dictionaryWithObjectsAndKeys:
          EntityFolder, ISyncRecordEntityNameKey,
          name, @"name",
          parent, @"parent",
          nil];
}

- (NSDictionary *)toDictionary {  
  return [NSDictionary dictionaryWithObjectsAndKeys:
          syncId, @"syncId",
          name, @"name",
          parent, @"parent",
          nil];
}

@end
