#import "LocalStorage.h"


@implementation LocalStorage

- (id)initWithPath:(NSString *)path_ {
  path = path_;
  return self;
}

- (id)initWithPathInApplicationSupport:(NSString *)path_ application:(NSString *)appName {
  
  NSFileManager *fileManager = [NSFileManager defaultManager];
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);    
  NSAssert([paths count] > 0, @"could not find ApplicationSupport directory");

  NSString *appSupportPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:appName];
  
  BOOL isDirectory;
  BOOL doesExist = [fileManager fileExistsAtPath:appSupportPath isDirectory:&isDirectory];
  
  if (!doesExist) {
    NSAssert1([fileManager createDirectoryAtPath:appSupportPath withIntermediateDirectories:NO 
                                      attributes:nil error:NULL],
              @"count not create directory: %@", appSupportPath);
  }
  else {
    NSAssert1(isDirectory, @"expected directory, but found file at: %@", appSupportPath);
  }
  
  path = [appSupportPath stringByAppendingPathComponent:path_];

  doesExist = [fileManager fileExistsAtPath:path isDirectory:&isDirectory];
  
  NSAssert1(!doesExist || (doesExist && !isDirectory), @"expected file at: %@", path);
  
  return self;
}

- (NSDictionary *)read {
  
  NSError *err = nil;
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:path] == NO) {
    NSLog(@"%@ does not exist; returning an empty dictionary",path);
    return [NSDictionary dictionary];
  }  
  
  NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingUncached error:&err];
  
  NSAssert2(err == nil, @"Error reading %@. %@", path, [err localizedDescription]);
  
  NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
  NSDictionary *dict = [NSPropertyListSerialization propertyListWithData:data options:0 format:&format error:&err];
  
  NSAssert2(err == nil, @"Error reading %@ as a property list. %@", path, [err localizedDescription]);
  
  return dict;  
}

- (void)write:(NSDictionary *)dict {
  
  NSError *err = nil;  
  NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
  NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict format:format options:0 error:&err];
  [data writeToFile:path options:0 error:&err];
  
  NSAssert2(err == nil, @"Error writing to %@. %@", path, [err localizedDescription]);    
}

@end
