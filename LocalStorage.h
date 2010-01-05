#import <Cocoa/Cocoa.h>


@interface LocalStorage : NSObject {
  NSString *path;
}

// Full path to the storage file.
- (id)initWithPath:(NSString *)path;

// ~/Library/Application Support/appName/path
- (id)initWithPathInApplicationSupport:(NSString *)path application:(NSString *)appName;

- (NSDictionary *)read;
- (void)write:(NSDictionary *)dict;

@end
