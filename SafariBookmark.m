#import "SafariBookmark.h"
#import <SyncServices/SyncServices.h>

@implementation SafariBookmark

@synthesize uuid, name, url, parent;

- (id)initWithSyncId:(NSString *)syncId_ name:(NSString *)name_ url:(NSURL *)url_ parent:(NSString *)parent_ {
  
  uuid = syncId_;
  name = name_;
  url = url_;
  parent = parent_;
  return self;
}

- (id)initFromDictionary:(NSDictionary *)plist {
  
  return [self initWithSyncId:[plist objectForKey:@"uuid"]
                         name:[plist objectForKey:@"name"] 
                          url:[NSURL URLWithString:[plist objectForKey:@"url"]] 
                       parent:[plist objectForKey:@"parent"]];
}

- (id)initFromSyncRecord:(NSDictionary *)record 
              identifier:(NSString *)identifier {
  
  return [self initWithSyncId:identifier
                         name:[record objectForKey:@"name"] 
                          url:[record objectForKey:@"url"]
                       parent:[record objectForKey:@"parent"]];
}


- (NSDictionary *)toDictionary {
  
  return [NSDictionary dictionaryWithObjectsAndKeys:
          EntityBookmark, ISyncRecordEntityNameKey,
          [url absoluteString], @"url",
          name, @"name",
          uuid, @"uuid",
          // parent may be nil, so it must go last
          parent, @"parent",
          nil];
}

- (SafariBookmark *) updateWithSyncRecord:(NSDictionary *)record {
  
  SafariBookmark *result = [SafariBookmark alloc];
  result->uuid = uuid;
  result->name = [record objectForKey:@"name"];
  result->url = [record objectForKey:@"url"];
  result->parent = [record objectForKey:@"parent"];
  
  return result;  
}


- (NSDictionary *)toSyncRecord {
  return [NSDictionary dictionaryWithObjectsAndKeys:
          EntityBookmark, ISyncRecordEntityNameKey,
          url, @"url",
          name, @"name",
          parent, @"parent",
          nil];
}

- (NSString*)href {
  return [url absoluteString];
}

@end
