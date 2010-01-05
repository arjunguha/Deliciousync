#import <Cocoa/Cocoa.h>

@interface SafariOutlineViewDataSource : NSObject < NSOutlineViewDataSource > {
  // An outline item is a two-element dictionary with type:
  //   mu item . { syncId: NSString, name: NSString, parent: NSArray, children: [ item ] }
  
  NSArray *outlineRoots;
  // All outline items, keyed by syncId.
  NSDictionary *outlineItems;
}

- (id)init;

- (void)outlineFromSyncRecords:(NSDictionary *)syncRecords;

- (id)outlineItemBySyncId:(NSString *)syncId;

//
// NSOutlineViewDataSource Protocol
//

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item;

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item;

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item;

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item;

@end
