#import "UISettings.h"
#import "Common.h"

@implementation UISettings

@synthesize username, password, destFolder, updateInterval, foldersOutlineData;

- (id)initWithUsername:(NSString *)username_
              password:(NSString *)password_
            destFolder:(NSString *)destFolder_
        updateInterval:(int)seconds
               folders:(NSDictionary *)foldersDict {
  
  username = username_;
  password = password_;
  destFolder = destFolder_;
  updateInterval = seconds;
  foldersOutlineData = foldersDict;
  return self;
}

- (id)initFromAgent:(NSString *)agentPath launchd:(NSString *)launchdPath {
  
  NSTask *task = [[NSTask alloc] init];
  NSPipe *pipe = [NSPipe pipe];
  
  [task setLaunchPath:agentPath];
  [task setArguments:[NSArray arrayWithObject:@"folders"]];
  [task setStandardOutput:pipe];
  
  [task launch];
  [task waitUntilExit];
  
  if ([task terminationStatus] != 0) {
    NSLog(@"DeliciousSync agent terminated with code %d",[task terminationStatus]);
    return nil;
  }
  
  NSData *data = [[pipe fileHandleForReading] readDataToEndOfFile];
  [[pipe fileHandleForReading] closeFile];
  
  NSError *err = nil;
  NSPropertyListFormat fmt = NSPropertyListXMLFormat_v1_0;
  NSDictionary *agentDict = [NSPropertyListSerialization propertyListWithData:data options:0 format:&fmt error:&err];
  
  //
  // Read update interval from launchd.plist file.
  //
  
  data = [NSData dataWithContentsOfFile:launchdPath];
  fmt = NSPropertyListXMLFormat_v1_0;
  NSDictionary *launchdDict = (data == nil 
                               ? [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:60]
                                                             forKey:@"StartInterval"]
                               : [NSPropertyListSerialization propertyListWithData:data 
                                                                           options:0 format:&fmt error:&err]);
  
  return [self initWithUsername:arrayOpt([agentDict valueForKey:@"deliciousUsername"])
                       password:[Common getPasswordForUsername:username]
                     destFolder:arrayOpt([agentDict valueForKey:@"destinationFolder"])
                 updateInterval:[[launchdDict valueForKey:@"StartInterval"] intValue]
                        folders:[agentDict valueForKey:@"folders"]];
}

- (void)writeSettingsToAgent:(NSString *)agentPath launchd:(NSString *)launchdPath {
  
  // 1. Save the Delicious password.
  
  [Common setPasswordForUsername:username password:password];
  
  // 2. Update the agent's settings.
  
  NSTask *task = [NSTask launchedTaskWithLaunchPath:agentPath
                                          arguments:[NSArray arrayWithObjects:
                                                     @"settings", destFolder == nil ? @"" : destFolder, username, nil]];
  
  [task waitUntilExit];

  // 3. Write a new launchd.plist file.

  NSLog(@"Writing to %@", launchdPath);
  
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        @"Deliciousync Agent", @"Label",
                        @"Aqua", @"LimitLoadToSessionType", 
                        [NSArray arrayWithObject:agentPath], @"ProgramArguments",
                        [NSNumber numberWithBool:YES], @"RunAtLoad",
                        [NSNumber numberWithBool:updateInterval == 0], @"Disabled",
                        [NSNumber numberWithInt:updateInterval], @"StartInterval",
                        @"/dev/null", @"StandardErrorPath",
                        @"/dev/null", @"StandardOutPath",
                        nil];
  
  NSError *err = nil;  
  NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict 
                                                            format:NSPropertyListXMLFormat_v1_0
                                                           options:0
                                                             error:&err];
  
  
  [data writeToFile:launchdPath options:0 error:&err];
  NSAssert2(err == nil, @"Error writing to %@: %@", launchdPath, [err localizedDescription]);
  
  // 4. Tell launchd about the new job

  [[NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" 
                            arguments:[NSArray arrayWithObjects:@"unload", launchdPath, nil]] waitUntilExit];
  [[NSTask launchedTaskWithLaunchPath:@"/bin/launchctl" 
                            arguments:[NSArray arrayWithObjects:@"load", launchdPath, nil]] waitUntilExit];
  
  
}  

- (BOOL)haveSettingsChanged:(UISettings *)oldSettings {
  return !([username isEqualToString:oldSettings.username] &&
           [password isEqualToString:oldSettings.password] &&
           [destFolder isEqualToString:oldSettings.destFolder] &&
           updateInterval == oldSettings.updateInterval);
}

- (id)copyWithZone:(NSZone *)zone {
  return [[UISettings allocWithZone:zone] initWithUsername:username
                                                  password:password
                                                destFolder:destFolder
                                            updateInterval:updateInterval
                                                   folders:foldersOutlineData];
}


@end
