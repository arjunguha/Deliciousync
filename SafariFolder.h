#import <Cocoa/Cocoa.h>

#define EntityFolder @"com.apple.bookmarks.Folder"

@interface SafariFolder : NSObject {
 @private
  NSString *syncId;
  NSArray *parent;
  NSString *name;
}

- (id)initWithSyncId:(NSString *)syncId 
                name:(NSString *)name
              parent:(NSArray *)parent;

- (id)initFromSyncRecord:(NSDictionary *)record identifier:(NSString *)syncId;

- (id)initFromDictionary:(NSDictionary *)dict;

- (NSDictionary *)toDictionary;
- (NSDictionary *)toSyncRecord;

@property (readonly) NSString *syncId;
@property (readonly) NSString *name;
@property (readonly) NSArray *parent;
@property (readonly) NSMutableArray *children;

@end
