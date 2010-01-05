#import <Cocoa/Cocoa.h>

@interface DeliciousyncAppDelegate : NSObject <NSApplicationDelegate> {
  NSWindow *window;
  BOOL canClose;  
}

- (void)setCanClose:(BOOL)aBool;

@property (assign) IBOutlet NSWindow *window;

@end
