#import <Cocoa/Cocoa.h>
#import "DeliciousyncAgent.h"


// DeliciousyncAgent action
int main(int argc, char *argv[]) {
  
  // Abort if we cannot gain an advisory lock on ~/Library/Application Support/Deliciousync/lock.
  {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    
    NSString *lockPath = [[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Deliciousync"]
                          stringByAppendingPathComponent:@"lock"];
    
    int fd = open([lockPath cStringUsingEncoding:NSUTF8StringEncoding], O_CREAT, S_IRWXU);
  
    if (fd < 0) {
      NSLog(@"Could not open lock file: %s", strerror(errno));
      return -1;
    }
    
    int result = flock(fd, LOCK_EX | LOCK_NB);
    if (result < 0 && errno == EWOULDBLOCK) {
      NSLog(@"waiting to acquire lock");
      result = flock(fd, LOCK_EX);
    }
    
    if (result < 0) {
      NSLog(@"Could not acquire lock: %s", strerror(errno));
      return -1;
    }
  }

  if (argc < 2 || strcmp(argv[1], "sync") == 0) {
    DeliciousyncAgent *agent = [[DeliciousyncAgent alloc] init];
    [agent sync];
  }
  else if (strcmp(argv[1], "register") == 0) {
    [DeliciousyncAgent registerClient];
  }
  else if (strcmp(argv[1], "refreshsync") == 0) {
    DeliciousyncAgent *agent = [[DeliciousyncAgent alloc] init];
    [agent refreshSync];
  }
  else if (strcmp(argv[1], "settings") == 0) {
    [DeliciousyncAgent updateDestFolder:[NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding]
                               username:[NSString stringWithCString:argv[3] encoding:NSUTF8StringEncoding]];
  }
  else if (strcmp(argv[1], "folders") == 0) {
    DeliciousyncAgent *agent = [[DeliciousyncAgent alloc] init];
    [agent prefsAndFolders];
  }
  else {
    NSLog(@"invalid command-line arguments");
    return -1;
  }
  
  return 0;
}