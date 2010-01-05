#import "SafariOutlineViewDataSource.h"
#import "SafariFolder.h"


@implementation SafariOutlineViewDataSource

- (id)init {
  
  outlineRoots = [NSArray array];
  outlineItems = [NSDictionary dictionary];
  return self;
}

+ (NSArray *)rootsFromItems:(NSDictionary *)items {
  
  NSMutableArray *roots = [NSMutableArray array];
  
  for (NSString *syncId in items) {
    NSDictionary *item = [items valueForKey:syncId];
    NSArray *parent = [item valueForKey:@"parent"];
    
    NSMutableArray *parentChildren = parent == nil 
      ? roots 
      : [[items valueForKey:[parent objectAtIndex:0]] valueForKey:@"children"];
    [parentChildren addObject:item];
  }
  
  return roots;
}

- (void)outlineFromSyncRecords:(NSDictionary *)syncRecords {
  
  NSMutableDictionary *items = [NSMutableDictionary dictionary];
  
  for (NSString *syncId in syncRecords) {
    NSDictionary *record = [syncRecords valueForKey:syncId];
    
    [items setValue:[NSDictionary dictionaryWithObjectsAndKeys:
                     syncId, @"syncId",
                     [record valueForKey:@"name"], @"name",
                     [NSMutableArray array], @"children",
                     [record valueForKey:@"parent"], @"parent",
                     nil]
             forKey:syncId];
  }
  
  outlineItems = items;
  outlineRoots = [SafariOutlineViewDataSource rootsFromItems:items];
}

- (id)outlineItemBySyncId:(NSString *)syncId {
  return [outlineItems valueForKey:syncId];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item {
  
  if (item == nil) {
    return [outlineRoots objectAtIndex:index];
  }
  else {
    return [[item valueForKey:@"children"] objectAtIndex:index];
  }
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item {
  
  return [[item valueForKey:@"children"] count] > 0;
}

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
  
  if (item == nil) {
    return [outlineRoots count];
  }
  else {
    return [[item valueForKey:@"children"] count];
  }
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
  return [item valueForKey:@"name"];
}

@end
