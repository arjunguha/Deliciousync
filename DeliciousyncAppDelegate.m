#import "DeliciousyncAppDelegate.h"

@implementation DeliciousyncAppDelegate

@synthesize window;

- (void)setCanClose:(BOOL)aBool {
  canClose = aBool;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
  canClose = NO;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
  if (canClose) {
    return NSTerminateNow;
  }
  
  if ([window isVisible]) {
    [window performClose:self];
  }
  
  return NSTerminateCancel;
}

@end
