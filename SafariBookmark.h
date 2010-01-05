#import <Cocoa/Cocoa.h>

#define EntityBookmark @"com.apple.bookmarks.Bookmark"

@interface SafariBookmark : NSObject {
@private
  NSString *uuid;
  NSString *name;
  NSURL *url;
  NSString *parent;
}

- (id)initFromSyncRecord:(NSDictionary *)record 
              identifier:(NSString *)identifier;

- (id)initFromDictionary:(NSDictionary *)plist;

- (SafariBookmark *) updateWithSyncRecord:(NSDictionary *)record;

- (NSDictionary *)toDictionary;

- (NSDictionary *)toSyncRecord;

@property (readonly) NSString *name;
@property (readonly) NSString *href;
@property (readonly) NSString *uuid;

@end