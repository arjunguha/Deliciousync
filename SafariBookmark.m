#import "SafariBookmark.h"
#import <SyncServices/SyncServices.h>

@implementation SafariBookmark

@synthesize uuid, name;

- (id)initFromDictionary:(NSDictionary *)plist {
  
  url = [NSURL URLWithString:[plist objectForKey:@"url"]];
  uuid = [plist objectForKey:@"uuid"];
  name = [plist objectForKey:@"name"];
  parent = [plist objectForKey:@"parent"];
  return self;
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

- (id)initFromSyncRecord:(NSDictionary *)record 
              identifier:(NSString *)identifier {
  
  uuid = identifier;
  url = [record objectForKey:@"url"];
  name = [record objectForKey:@"name"];
  parent = [record objectForKey:@"parent"];
  
  NSLog(@"Received Safari bookmark %@", [url absoluteString]);
  
  return self;
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
