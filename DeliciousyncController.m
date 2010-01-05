#import "DeliciousyncController.h"
#import "DeliciousyncAppDelegate.h"
#import "Common.h"

@implementation DeliciousyncController

- (void) copyIfNewerTo:(NSString *)dest from:(NSString *)src {

  NSError *err;
  NSFileManager *fileManager = [NSFileManager defaultManager];

  BOOL isDirectory;
  BOOL fileExists = [fileManager fileExistsAtPath:dest isDirectory:&isDirectory];
  
  // fileExists implies !isDirectory
  NSAssert1(!fileExists || !isDirectory, @"expected a file at %@", dest);
  
  if (!fileExists) {
    NSLog( @"copying from the bundle to %@", dest);
    NSAssert2([fileManager copyItemAtPath:src toPath:dest error:&err],
              @"failed to copy item %@: %@", src, [err localizedDescription]);
  }
  else if ([[[fileManager attributesOfItemAtPath:src error:&err] fileModificationDate] 
            compare: [[fileManager attributesOfItemAtPath:dest error:&err] fileModificationDate]]
           == NSOrderedDescending) {
    NSLog(@"replacing %@ with the newer item in the bundle", dest);
    NSAssert2([fileManager removeItemAtPath:dest error:&err],
              @"failed to remove %@: %@", dest, [err localizedDescription]);
    NSAssert2([fileManager copyItemAtPath:src toPath:dest error:&err],
              @"failed to copy %@: %@", src, [err localizedDescription]);
  }
}

- (void)copyClientDescription {

  NSFileManager *fileManager = [NSFileManager defaultManager];
  
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);    
  NSString *appSupportPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"Deliciousync"];
  
  BOOL isDirectory, fileExists;
  
  //
  // Ensure ~/Library/Application Support/Deliciousync exists and is a directory.  Create it if necessarry.
  //
  
  fileExists = [fileManager fileExistsAtPath:appSupportPath isDirectory:&isDirectory];
   
  if (!fileExists) {
    NSAssert1([fileManager createDirectoryAtPath:appSupportPath 
                     withIntermediateDirectories:YES 
                                      attributes:nil 
                                           error:nil],
              @"failed to create directory %@", appSupportPath);
  }
  NSAssert1(isDirectory, @"expected directory at %@", appSupportPath);
  
  //
  // Copy items from the bundle
  //
  
  agentPath = [appSupportPath stringByAppendingPathComponent:@"DeliciousyncAgent"];
  [self copyIfNewerTo:agentPath
                 from:[[NSBundle mainBundle] pathForResource:@"DeliciousyncAgent" ofType:nil]];
  
  [self copyIfNewerTo:[appSupportPath stringByAppendingPathComponent:@"DeliciousyncAgentClientDescription.plist"]
                 from:[[NSBundle mainBundle] pathForResource:@"DeliciousyncAgentClientDescription" ofType:@"plist"]];
}

- (void)awakeFromNib {
  
  [self copyClientDescription];
  
  launchdSettingsPath = [@"~/Library/LaunchAgents/DeliciousyncAgent.plist" stringByExpandingTildeInPath];
  
  // TODO: check to see if nil
  settings = [[UISettings alloc] initFromAgent:agentPath launchd:launchdSettingsPath];
  originalSettings = [settings copy];
  
  if (settings.username != nil) {
    [usernameField setStringValue:settings.username];
  }
  
  if (settings.password != nil) {
    [passwordField setStringValue:settings.password];
  }
  
  int interval = settings.updateInterval;
  if (interval == 0) {
    [intervalSlider setIntValue:11];
  }
  else if (interval >= 60 && interval <= 10 * 60) {
    [intervalSlider setIntValue: interval / 60];
  }
  else {
    // TODO: set a custom flag
    [intervalSlider setIntValue:11];
  }
    
  
  [bookmarksOutlineData outlineFromSyncRecords:settings.foldersOutlineData];
  [folderChooser reloadData];
  

  
  // Select the destination folder.
  [folderChooser expandItem:nil expandChildren:YES];
  id item = [bookmarksOutlineData outlineItemBySyncId:settings.destFolder];
  [folderChooser selectRowIndexes:[NSIndexSet indexSetWithIndex:[folderChooser rowForItem:item]]
             byExtendingSelection:NO];
}

// Returns YES if settings have changed.
- (BOOL)updateSettings {
  settings.username = [usernameField stringValue];
  settings.password = [passwordField stringValue];
  settings.destFolder = [[folderChooser itemAtRow:[folderChooser selectedRow]] valueForKey:@"syncId"];
  int interval = [intervalSlider intValue];
  settings.updateInterval = interval == 11 ? 0 : interval * 60;

  return [settings haveSettingsChanged:originalSettings];
}

- (IBAction)saveSettings:(id)sender {
  
  if ([self updateSettings]) {
    [settings writeSettingsToAgent:agentPath launchd:launchdSettingsPath];
    originalSettings = settings;
    
  }
}

- (BOOL)windowShouldClose:(id)sender {
  
  NSApplication *app = [NSApplication sharedApplication];
  DeliciousyncAppDelegate *appDelegate = [app delegate];
  
  if (![self updateSettings]) {
    [appDelegate setCanClose:true];
    [app terminate:self];      
    return YES;
  }
  
  NSAlert *alert = [[NSAlert alloc] init];
  [alert setInformativeText:@"Do you want to save settings?"];
  [alert setMessageText:@"Settings Changed"];
  [alert addButtonWithTitle:@"Save"];
  [alert addButtonWithTitle:@"Cancel"];
  [alert addButtonWithTitle:@"Discard"];
  

  switch ([alert runModal]) {
    case NSAlertFirstButtonReturn: {
      // Save changes
      [settings writeSettingsToAgent:agentPath launchd:launchdSettingsPath];
      [appDelegate setCanClose:true];
      [app terminate:self];      
      return YES;
    }
    case NSAlertSecondButtonReturn: {
      [appDelegate setCanClose:false];
      return NO;
    }
    case NSAlertThirdButtonReturn: {
      // Discard changes and close
      [appDelegate setCanClose:true];
      [app terminate:self];
      return YES;
    }
    default: {
      NSAssert(NO, @"unexpected fallthrough in switch");
      return YES;
    }
  }
}

- (IBAction)displayLicense:(id)sender {
  [[NSWorkspace sharedWorkspace] openFile:[[NSBundle mainBundle] pathForResource:@"License" ofType:@"txt"]];
}

@end
