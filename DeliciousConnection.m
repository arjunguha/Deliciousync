#import "DeliciousConnection.h"


@implementation DeliciousConnection

- (id) initWithUsername:(NSString *)username_ Password:(NSString *)password_ {
  username = username_;
  password = password_;
  req = [[NSMutableURLRequest alloc] init];
  [req setValue:@"arjun@cs.brown.edu" forHTTPHeaderField:@"User-Agent"];
  
  lastRequestTime = 0.0f;
  requestDelay = 1.0f;
  
  resp = [[NSHTTPURLResponse alloc] init];
  error = [NSError alloc];
  
  return self;
}

- (NSXMLDocument *)requestPath:(NSString *)path {
  
  NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://%@:%@@api.del.icio.us/%@", 
                                     username, password, path]];
    
  [req setURL:url];
  
  // Ensure __requestDelay seconds have passed since the last request.
  // Halve __requestDelay if it is longer than a second.
  NSTimeInterval now = [[[NSDate alloc] init] timeIntervalSince1970];
  
  if (lastRequestTime + requestDelay > now) {
    NSLog(@"Sleeping for %d", lastRequestTime + requestDelay - now);
    sleep(lastRequestTime + requestDelay - now);
    lastRequestTime = [[[NSDate alloc] init] timeIntervalSince1970];
    requestDelay = MAX(1,requestDelay / 2);        
  }
  
  data = [NSURLConnection sendSynchronousRequest:req 
                               returningResponse:&resp 
                                           error:&error];
  
  switch (resp.statusCode) {
    case 200: {
      NSXMLDocument *xml = [[NSXMLDocument alloc] initWithData:data options:0 error:&error];
      if (xml == nil) {
        @throw [NSException exceptionWithName:@"Deliciousync" 
                                       reason:@"Malformed response from Delicious"
                                     userInfo:[error userInfo]];
      }
      else {
        return xml;
      }
      break;
    }
    case 503:
      // Throttled
      requestDelay = MIN(32,requestDelay * 2);
    default:
      @throw [NSException exceptionWithName:@"Deliciousync" 
                                     reason:[NSString stringWithFormat:@"Delicious responded with code %d", 
                                             resp.statusCode]
                                   userInfo:nil];
  }
}
@end