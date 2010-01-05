#import <Cocoa/Cocoa.h>

@interface DeliciousPost : NSObject {
  
@private
  NSString *description;
  NSString *href;
  NSString *meta;
  NSString *hash;
  NSArray *tags;
}

// Computes an MD5 sum with lowercase letters, suitable for Delicious.
+ (NSString *)md5:(NSString *)str;

- (id)initWithUrl:(NSString *)url description:(NSString *)description meta:(NSString *)meta tags:(NSArray *)tags;


// Deserialization from the local cache.
- (id)initFromDictionary:(NSDictionary *)dict;

// Create from a DeliciousPost.
- (id) initWithXML:(NSXMLElement *)xml;

// Create from a sync-record.

// Serialization to the local cache.
- (NSDictionary *)toDictionary;

@property (readonly) NSString *description;
@property (readonly) NSString *href;
@property (readonly) NSString *meta;
@property (readonly) NSString *hash;
@property (readonly) NSArray *tags;

@end