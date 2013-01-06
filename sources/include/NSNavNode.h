/*
 *  NSNavNode.h
 *  gDisk
 *
 *  Created by Wagner Marie on 03/02/2006.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@interface NSNavNode : NSObject

+ (void) initialize;
+ (id) navNodeWithSimpleQueryString: (id) parameter1 searchScopeNode: (id) parameter2;
+ (Class) previewHelperClass;

- (id) ancestorsStartingWith: (id) parameter1;
- (id) children;
- (void) dealloc;
- (id) description;
- (id) fastGetPreviewThumbnailImage;
- (void) finalize;
- (void) flushAllCaches;
- (id) getNodeAsContainerNodeForBrowsing: (char) parameter1;
- (id) getNodeAsDeepResolvedNode: (char) parameter1;
- (id) getNodeAsInfoNode: (char) parameter1;
- (id) getNodeAsResolvedNode: (char) parameter1;
- (char) isDescendantOfNode: (id) parameter1;
- (char) isQuery;
- (char) isSearchable;
- (char) isValid;
- (id) previewThumbnailImage;
- (id) queryHitResultsFilterUTIs;
- (void) registerForPropertyChangedNotifications;
- (void) releaseCaches;
- (void) retainCaches;
- (id) searchScopeDisplayName;
- (void) setQueryHitResultsFilterUTIs: (id) parameter1;
- (void) setSortDescriptors: (id) parameter1;
- (id) sortDescriptors;
- (char) sortsChildrenEfficiently;
- (void) unregisterForPropertyChangedNotifications;
- (id) utiAsString;

@end

@interface NSNavNode(NSNavPhysicalSizeComparisonAdditions)

- (int) _physicalSizeCompare: (id) parameter1;

@end


