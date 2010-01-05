#import <Cocoa/Cocoa.h>
#import "DeliciousPost.h"
#import "DeliciousConnection.h"

@interface DeliciousSync : NSObject <NSCopying> {
@private
  DeliciousConnection *conn;
  
  NSMutableDictionary *posts;
  NSDate *lastPullFromDelicious;
}

+ (NSDate *)ISO8601ToNSDate:(NSString *)str;
+ (NSString *)NSDateToISO8601:(NSDate *)date;

+ (NSString *)escapeQueryValue:(NSString *)original;
+ (NSString *)unescapeQueryValue:(NSString *)escaped;

- (id)init:(DeliciousConnection *)conn;
- (id)initFromDictionary:(NSDictionary *)dict connection:(DeliciousConnection *)connection;

- (NSDictionary *)toDictionary;

- (void)addPost:(DeliciousPost *)post;
- (void)removePostByHash:(NSString *)hash;
- (NSArray *)allPosts;
- (DeliciousPost *)postByHash:(NSString *)hash;

- (void)pullFromDelicious;
- (void)pushToDelicious:(NSArray *)removedUrls modified:(NSArray *)modifiedPosts;

- (id)copyWithZone:(NSZone *)zone;

@end
