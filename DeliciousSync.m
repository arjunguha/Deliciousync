#import "DeliciousSync.h"

@implementation DeliciousSync

+ (NSDate *)ISO8601ToNSDate:(NSString *)str {
  
  NSArray *datetimez = [str componentsSeparatedByString:@"T"];
  NSString  *date = [datetimez objectAtIndex:0];
  NSArray *timez = 
  [[datetimez objectAtIndex:1] componentsSeparatedByString:@"Z"];
  NSString *time = [timez objectAtIndex:0];
  
  NSString *dateString = [NSString stringWithFormat:@"%@ %@ -0000",date,time];
  
  return [[NSDate alloc] initWithString:dateString];
}


+ (NSString *)NSDateToISO8601:(NSDate *)date {
  
  NSTimeZone *tz = [NSTimeZone timeZoneWithAbbreviation:@"UTC"];
  return [date descriptionWithCalendarFormat:@"%Y-%m-%dT%H:%M:%SZ"
                                    timeZone: tz
                                      locale:nil];
}

// In addition to normally escaped characters, this method also escapes '&', '?', and '=' for compatibility with GET
// requests.
+ (NSString *)escapeQueryValue:(NSString *)original {
  
  CFStringRef escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)original, NULL,
                                                                (CFStringRef)@"&?=", 
                                                                kCFStringEncodingUTF8);
  NSString *result = [NSString stringWithString:(NSString *)escaped];
  CFRelease(escaped);
  return result;  
}

+ (NSString *)unescapeQueryValue:(NSString *)escaped {
  return [escaped stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (id)init:(DeliciousConnection *)conn_ {
  
  conn = conn_;
  lastPullFromDelicious = [NSDate distantPast];
  posts = [[NSMutableDictionary alloc] init];
  return self;
}

- (id)initFromDictionary:(NSDictionary *)dict connection:(DeliciousConnection *) connection {
  
  conn = connection;
  
  lastPullFromDelicious = [DeliciousSync ISO8601ToNSDate:[dict valueForKey:@"lastPull"]];
  
  NSDictionary *postDict = [dict valueForKey:@"posts"];
  posts = [NSMutableDictionary dictionaryWithCapacity:[postDict count]];
  for (NSString *hash in postDict) {
    [posts setValue:[[DeliciousPost alloc] initFromDictionary:[postDict valueForKey:hash]]
             forKey:hash];
  }
  
  return self;
}
    
- (NSDictionary *)toDictionary {
  
  NSMutableDictionary *postsDict = [NSMutableDictionary dictionaryWithCapacity:[posts count]];
  
  for (NSString *hash in posts) {
    [postsDict setValue:[[posts valueForKey:hash] toDictionary] 
                 forKey:hash];
  }
  
  return [NSDictionary dictionaryWithObjectsAndKeys:
          postsDict, @"posts",
          [DeliciousSync NSDateToISO8601:lastPullFromDelicious], @"lastPull",
          nil];
}

- (BOOL)deliciousHasUpdates {
  NSXMLDocument* doc = [conn requestPath:@"v1/posts/update"];
  NSXMLElement* xml = [doc rootElement];
  
  NSAssert1([@"update" isEqualToString:[xml name]], @"expected <update>, received %@", doc);
  NSDate* lastWebUpdate = [DeliciousSync ISO8601ToNSDate:[[xml attributeForName:@"time"] stringValue]];
  
  return [lastWebUpdate compare:lastPullFromDelicious] == NSOrderedDescending;
}

- (void)addPost:(DeliciousPost *)post {
  [posts setValue:post forKey:post.hash];
}

- (void)removePostByHash:(NSString *)hash {  
  [posts removeObjectForKey:hash];
}

- (NSArray *)allPosts {
  return [posts allValues];
}


- (NSMutableDictionary *)posts {
  return posts;
}

- (DeliciousPost *)postByHash:(NSString *)hash {
  return [posts valueForKey:hash];
}


- (void)pullFromDelicious {
  
  NSLog(@"Pulling from Delicious...");
  //
  // Get a list of URL hashes (hash) and content hashes (meta).
  //
  
  NSXMLDocument *doc = [conn requestPath:@"v1/posts/all?hashes"];
  NSXMLElement *xml = [doc rootElement];
  
  NSAssert1([@"posts" isEqualToString:[xml name]], @"expected <posts>, received %@", doc);
  
  // Figure out which posts were created, modified, or deleted.
  
  // If Delicious does not return a hash, it's been deleted.
  NSMutableSet *hashesFromDelicious = [[NSMutableSet alloc] init];
  // Hashes of posts that have changed on Delicious.
  NSMutableSet *updatedHashes = [[NSMutableSet alloc] init];
  int numRemoved = 0;
  
  for (NSXMLElement *xmlPost in [xml children]) {
    NSString *hash = [[xmlPost attributeForName:@"url"] stringValue];
    NSString *meta = [[xmlPost attributeForName:@"meta"] stringValue];
    
    [hashesFromDelicious addObject:hash];
    
    DeliciousPost *post = [posts objectForKey:hash];
    if (post == nil || [post.meta isEqualToString:meta] == NO) {
      [updatedHashes addObject:hash]; // creation and modification are treated the same
    }
  }
  
  for (NSString *hash in [posts allKeys]) {
    if ([hashesFromDelicious containsObject:hash] == NO) {
      numRemoved++;
      [posts removeObjectForKey:hash];
    }
  }
  
  NSLog(@"%d update(s) and %d delete(s) from Delicious", [updatedHashes count], numRemoved);
  
  //
  // Request all posts that were created or modified.
  //
  
  doc = [conn requestPath:[@"v1/posts/get?meta=yes&hashes=" 
                           stringByAppendingString:[[updatedHashes allObjects] componentsJoinedByString:@"+"]]];
  xml = [doc rootElement];
  NSAssert1([@"posts" isEqualToString:xml.name], 
            @"expected <posts>, received %@", xml);
  
  lastPullFromDelicious = [[NSDate alloc] init];
  
  for (NSXMLElement* xmlPost in [xml children]) {
    NSString *hash = [[xmlPost attributeForName:@"hash"] stringValue];
    [posts setValue:[[DeliciousPost alloc] initWithXML:xmlPost]
             forKey:hash];
  }
}

// Uses removedPosts and modifiedPosts to send updates to Delicious.  Once
// updates are complete, removedPosts and modifiedPosts are cleared.
- (void)pushToDelicious:(NSArray *)removedUrls modified:(NSArray *)modifiedPosts { 
  
  NSLog(@"%d update(s) and %d delete(s) for Delicious", [modifiedPosts count], [removedUrls count]);
  
  for (NSString *url in removedUrls) {
    NSLog(@"Removing %@ from Delicious", url);
    [conn requestPath:[NSString stringWithFormat:@"v1/posts/delete?url=%@", [DeliciousSync escapeQueryValue:url]]];
  }
  
  
  for (DeliciousPost *post in modifiedPosts) {
    NSLog(@"Pushing updates to %@", post.href);
    NSString *escapedUrl = [DeliciousSync escapeQueryValue:post.href];
    NSString *escapedDescription = [DeliciousSync escapeQueryValue:post.description];
    
    NSString *req = [NSString stringWithFormat:@"v1/posts/add?url=%@&description=%@&replace=yes",
                     escapedUrl, escapedDescription];
    [conn requestPath:req];
  }
}

- (id)copyWithZone:(NSZone *)zone {
  
  DeliciousSync *newObj = [DeliciousSync allocWithZone:zone];
  newObj->conn = conn;
  newObj->posts = [posts mutableCopyWithZone:zone];
  newObj->lastPullFromDelicious = [lastPullFromDelicious copyWithZone:zone];
  return self;
}

@end
