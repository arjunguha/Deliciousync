#import <Cocoa/Cocoa.h>
#import "SafariOutlineViewDataSource.h"
#import "UISettings.h"

@interface DeliciousyncController : NSObject {
  
 @private
  UISettings *settings;
  UISettings *originalSettings;
  
  NSString *launchdSettingsPath; 
  NSString *agentPath;
  
  IBOutlet NSWindow *appWindow;
  IBOutlet SafariOutlineViewDataSource *bookmarksOutlineData;
  IBOutlet NSOutlineView *folderChooser;
  IBOutlet NSTextField *usernameField;
  IBOutlet NSSecureTextField *passwordField;
  IBOutlet NSTextField *infoField;
  IBOutlet NSSlider *intervalSlider;
}

- (void)awakeFromNib;
- (BOOL)windowShouldClose:(id)sender;
- (IBAction)displayLicense:(id)sender;
- (IBAction)saveSettings:(id)sender;

@end
