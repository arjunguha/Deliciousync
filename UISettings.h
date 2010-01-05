#import <Cocoa/Cocoa.h>


@interface UISettings : NSObject <NSCopying> {
  NSString *username;
  NSString *password;
  NSString *destFolder;
  int updateInterval;
  NSDictionary *foldersOutlineData;
}

- (id)initWithUsername:(NSString *)username 
              password:(NSString *)password 
            destFolder:(NSString *)destFolder
        updateInterval:(int)seconds
               folders:(NSDictionary *)foldersDict;

- (id)initFromAgent:(NSString *)agentPath launchd:(NSString *)launchdPath;

- (void)writeSettingsToAgent:(NSString *)agentPath launchd:(NSString *)launchdPath;

- (BOOL)haveSettingsChanged:(UISettings *)oldSettings;

@property (assign) NSString *username;
@property (assign) NSString *password;
@property (assign) NSString *destFolder;
@property (assign) int updateInterval;
@property (readonly) NSDictionary *foldersOutlineData; // does not make sense to set this property

// NSCopying
- (id)copyWithZone:(NSZone *)zone;

@end
