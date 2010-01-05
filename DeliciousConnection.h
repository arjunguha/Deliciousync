#import <Cocoa/Cocoa.h>

// A connection to api.del.icio.us that throttles appropriately.
@interface DeliciousConnection : NSObject {
  @private
  NSString *username;
  NSString *password;
  NSMutableURLRequest *req;
  NSHTTPURLResponse *resp;
  NSTimeInterval lastRequestTime;
  NSTimeInterval requestDelay;
  NSData *data;
  NSError *error;
}

- (id)initWithUsername:(NSString *)username Password:(NSString *)password;

- (NSXMLDocument *)requestPath:(NSString *)path;

@end
