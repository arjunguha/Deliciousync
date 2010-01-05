#import "DeliciousPost.h"
#import <SyncServices/SyncServices.h>
#import <CommonCrypto/CommonDigest.h>

@implementation DeliciousPost

@synthesize description, href, meta, hash, tags;

+ (NSString *) md5:(NSString *)str {
  const char *cStr = [str UTF8String];
  unsigned char result[CC_MD5_DIGEST_LENGTH];
  CC_MD5(cStr, strlen(cStr), result);
  return [NSString stringWithFormat:
          @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
          result[0], result[1], result[2], result[3], result[4], result[5], 
          result[6], result[7], result[8], result[9], result[10], result[11], 
          result[12], result[13], result[14], result[15]];
}

- (id)initWithUrl:(NSString *)url_ description:(NSString *)description_ meta:(NSString *)meta_ tags:(NSArray *)tags_ {
  
  href = url_;
  description = description_;
  tags = tags_;
  meta = meta_;
  hash = [DeliciousPost md5:href];
  tags = tags_;
  
  return self;
}

- (id)initFromDictionary:(NSDictionary *)dict {
  return [self initWithUrl:[dict objectForKey:@"url"]
               description:[dict objectForKey:@"description"]
                      meta:[dict objectForKey:@"meta"]
                      tags:[dict objectForKey:@"tags"]];
}

- (NSDictionary *)toDictionary {
  return [NSDictionary dictionaryWithObjectsAndKeys:
          description, @"description",
          meta, @"meta",
          href, @"url",
          tags, @"tags",
          nil];
}

- (id) initWithXML:(NSXMLElement*)xml {
  return [self initWithUrl:[[xml attributeForName:@"href"] stringValue]
               description:[[xml attributeForName:@"description"] stringValue]
                      meta:[[xml attributeForName:@"meta"] stringValue] 
                      tags:[[[xml attributeForName:@"tags"] stringValue] componentsSeparatedByString:@" "]];
}

@end
