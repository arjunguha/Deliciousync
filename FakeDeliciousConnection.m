#import "FakeDeliciousConnection.h"
#import "DeliciousSync.h"
#import "DeliciousPost.h"
#include <sys/types.h>
#include <sys/event.h>
#include <sys/time.h>

@implementation FakeDeliciousConnection

// Returns a dictionary of strings that represents the query portion of a url (key1=value1&key2=value2& ...).
+ (NSDictionary *)urlQueryAsDictionary:(NSURL *)url {
  
  NSString *query = [url query];
  NSArray *pairs = [query componentsSeparatedByString:@"&"];
  
  NSMutableDictionary *result = [NSMutableDictionary dictionaryWithCapacity:[pairs count]];
  
  for (NSString *pair in pairs) {
    NSArray *kvs = [pair componentsSeparatedByString:@"="];
    NSAssert1([kvs count] <= 2, @"malformed query: %@", query);
    [result setValue:[kvs count] == 2 ? [DeliciousSync unescapeQueryValue:[kvs objectAtIndex:1]] : @""
              forKey:[kvs objectAtIndex:0]];
  }
  
  return result;
}

- (id)initWithPath:(NSString *)path {
  
  cachePath = path;
  
  if ([[NSFileManager defaultManager] fileExistsAtPath:cachePath]) {
    [self load];
  }
  else {  
    posts = [[NSMutableDictionary alloc] init];
    lastUpdateTime = [NSDate date];
  }
  
  return self;
}

- (void)load {

  NSError *err = nil;  
  NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
  NSDictionary *dict = [NSPropertyListSerialization propertyListWithData:[NSData dataWithContentsOfFile:cachePath]
                                                                 options:0 
                                                                  format:&format 
                                                                   error:&err];
  
  NSAssert1(err == nil, @"Error loading local cache: %@", [err localizedDescription]);
    
  NSArray *postsArray = [dict valueForKey:@"posts"];
  NSMutableDictionary *newPosts = [NSMutableDictionary dictionaryWithCapacity:[postsArray count]];
  
  for (NSDictionary *postDict in postsArray) {
    DeliciousPost *post = [[DeliciousPost alloc] initFromDictionary:postDict];
    [newPosts setValue:post forKey:post.hash];
  }
  
  posts = newPosts;
  lastUpdateTime = [DeliciousSync ISO8601ToNSDate:[dict valueForKey:@"time"]];
}


- (void)save {
  
  NSMutableArray *postsArray = [NSMutableArray arrayWithCapacity:[posts count]];
  for (NSString *hash in posts) {
    [postsArray addObject:[[posts valueForKey:hash] toDictionary]];
  }
  
  NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
                        postsArray, @"posts",
                        [DeliciousSync NSDateToISO8601:lastUpdateTime], @"time",
                        nil];
  
  NSError *err = nil;  
  
  NSPropertyListFormat format = NSPropertyListBinaryFormat_v1_0;
  
  NSData *data = [NSPropertyListSerialization dataWithPropertyList:dict format:format options:0 error:&err];
  
  [data writeToFile:cachePath options:0 error:&err];
  
  NSAssert1(err == nil, @"Error storing to local cache: %@", [err localizedDescription]);  
}

- (NSXMLDocument *)v1_posts_update:(NSURL *)req {
  
  NSXMLElement *xml = [NSXMLNode elementWithName:@"update"];
  [xml addAttribute:[NSXMLNode attributeWithName:@"time" 
                                     stringValue:[DeliciousSync NSDateToISO8601:lastUpdateTime]]];
  return [NSXMLNode documentWithRootElement:xml];
}

- (NSXMLDocument *)v1_posts_all_hashes:(NSURL *)req {

  NSXMLElement *xml = [NSXMLNode elementWithName:@"posts"];

  for (NSString *hash in posts) {
    DeliciousPost *post = [posts valueForKey:hash];
    NSXMLElement *postXml = [NSXMLNode elementWithName:@"post"];
    [postXml addAttribute:[NSXMLNode attributeWithName:@"url" stringValue:hash]];
    [postXml addAttribute:[NSXMLNode attributeWithName:@"meta" stringValue:post.meta]];
    [xml addChild:postXml];
  }
    
  return [NSXMLNode documentWithRootElement:xml];
}

- (NSXMLDocument *)v1_posts_get:(NSURL *)req {

  NSDictionary *query = [FakeDeliciousConnection urlQueryAsDictionary:req];
  
  NSAssert1([[query objectForKey:@"meta"] isEqualToString:@"yes"],
            @"expected meta=yes in query: %@", [req query]);
  
  NSArray *hashes = [[query objectForKey:@"hashes"] componentsSeparatedByString:@"+"];

  NSMutableArray *postXmls = [NSMutableArray arrayWithCapacity:[hashes count]];
  
  for (NSString *hash in hashes) {
    if (![hash isEqualToString:@""]) {
      DeliciousPost *post = [posts valueForKey:hash];
      NSXMLElement *postXml = [NSXMLNode elementWithName:@"post"];
      [postXml addAttribute:[NSXMLNode attributeWithName:@"href" stringValue:post.href]];
      [postXml addAttribute:[NSXMLNode attributeWithName:@"hash" stringValue:post.hash]];
      [postXml addAttribute:[NSXMLNode attributeWithName:@"description" stringValue:post.description]];
      [postXml addAttribute:[NSXMLNode attributeWithName:@"meta" stringValue:post.meta]];
      [postXml addAttribute:[NSXMLNode attributeWithName:@"tag" 
                                             stringValue:[post.tags componentsJoinedByString:@" "]]];
      [postXmls addObject:postXml];
    }
  }
  
  NSXMLElement *postsXml = [NSXMLNode elementWithName:@"posts"];
  [postsXml insertChildren:postXmls atIndex:0];
  return [NSXMLNode documentWithRootElement:postsXml];
}

- (NSXMLDocument *)v1_posts_delete:(NSURL *)req {
  
  NSDictionary *query = [FakeDeliciousConnection urlQueryAsDictionary:req];
  
  NSString *escapedUrl = [query valueForKey:@"url"];
  NSAssert1(escapedUrl != nil, @"expected delete= in %@",[req query]);
  
  NSString *hash = [DeliciousPost md5:[DeliciousSync unescapeQueryValue:escapedUrl]];
  
  NSAssert1([posts valueForKey:hash] != nil, @"no post with URL %@", [DeliciousSync unescapeQueryValue:escapedUrl]);
  
  [posts removeObjectForKey:hash];
  
  lastUpdateTime = [NSDate date];
  [self save];
  
  return [NSXMLNode document];  
}

- (NSXMLDocument *)v1_posts_add:(NSURL *)req {
  
  NSDictionary *query = [FakeDeliciousConnection urlQueryAsDictionary:req];
  
  NSString *url = [query valueForKey:@"url"];
  NSString *desc = [query valueForKey:@"description"];
  
  NSAssert1(url != nil && desc != nil && [[query valueForKey:@"replace"] isEqualToString:@"yes"],
            @"expected replace=yes, url=*, and description=* in %@", [req query]);
  
  NSString *meta = [DeliciousSync NSDateToISO8601:[NSDate date]];
  
  [posts setValue:[[DeliciousPost alloc] initWithUrl:url 
                                         description:desc
                                                meta:meta 
                                                tags:[NSArray array]]
           forKey:[DeliciousPost md5:url]];
  
  lastUpdateTime = [NSDate date];
  [self save];
  
  return [NSXMLNode document];  
}

- (NSXMLDocument *) requestPath:(NSString *)req {
  
  NSURL *url = [NSURL URLWithString:req];
  
  NSString *path = [url path];
  if ([path isEqualToString:@"v1/posts/all"]) {
    return [self v1_posts_all_hashes:url];
  }
  else if ([path isEqualToString:@"v1/posts/update"]) {
    return [self v1_posts_update:url];
  }
  else if ([path isEqualToString:@"v1/posts/get"]) {
    return [self v1_posts_get:url];
  }
  else if ([path isEqualToString:@"v1/posts/delete"]) {
    return [self v1_posts_delete:url];
  }
  else if ([path isEqualToString:@"v1/posts/add"]) {
    return [self v1_posts_add:url];
  }
  else {
    NSAssert1(NO, @"unexpected url: %@", url);
    return nil;
  }
}



@end
