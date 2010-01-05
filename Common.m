#import "Common.h"

NSString* pathInAppSupport(NSString *path) {
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);    
  NSString *appSupportPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Deliciousync"];
  return [appSupportPath stringByAppendingPathComponent:path];
}

// Sync Services uses arrays as option types. A zero-length array is None. A singleton array is Some of 'a. arrayOpt
// returns nil for zero-length arrays and the element at index 0 for other arrays.
id arrayOpt(NSArray *array) {
  if ([array count] == 0) {
    return nil;
  }
  else {
    return [array objectAtIndex:0];
  }
}

@implementation Common


+ (NSString *)getPasswordForUsername:(NSString *)username {
  const char *serviceName = "Deliciousync";
  
  UInt32 passwordLength;
  void *passwordData;
  
  OSStatus r = 
  SecKeychainFindGenericPassword(NULL, strlen(serviceName), serviceName, 
                                 username.length, [username cStringUsingEncoding:NSASCIIStringEncoding],
                                 &passwordLength, &passwordData, NULL);
  
  if (r != noErr) {
    NSLog(@"Error finding password for %@. %@", username, 
          [NSError errorWithDomain:NSOSStatusErrorDomain code:r userInfo:nil]);
    return nil;
  }
  
  NSString *password = [[NSString alloc] initWithCString:(const char*)passwordData length:passwordLength];
  
  r = SecKeychainItemFreeContent(NULL, passwordData);
  if (r != noErr) {
    NSLog(@"Error freeing password for %@. %@", username, 
          [NSError errorWithDomain:NSOSStatusErrorDomain code:r userInfo:nil]);
    return nil;
  }
  
  return password;
}

+ (void )setPasswordForUsername:(NSString *)username password:(NSString *)password {
  const char *serviceName = "Deliciousync";
  OSStatus r = SecKeychainAddGenericPassword(NULL, strlen(serviceName), 
                                             serviceName, username.length, 
                                             [username cStringUsingEncoding:NSASCIIStringEncoding],
                                             password.length, [password cStringUsingEncoding:NSASCIIStringEncoding],
                                             NULL);
  NSLog(@"Stored password for %@ in the Keychain, result: %d", username, r);
}

@end