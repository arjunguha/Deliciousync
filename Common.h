#import <Cocoa/Cocoa.h>

NSString* pathInAppSupport(NSString *path);
id arrayOpt(NSArray *array);

@interface Common : NSObject {
}

+ (NSString *)getPasswordForUsername:(NSString *)username;
+ (void )setPasswordForUsername:(NSString *)username password:(NSString *)password;

@end