/*
 *  NSNavSidebarScrollView.h
 *  gDisk
 *
 *  Created by Wagner Marie on 03/02/2006.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@interface NSNavSidebarScrollView : NSScrollView
{
	
}

- (void) awakeFromNib;
- (void) dealloc;
- (void) finalize;
- (char) isOpaque;
- (void) resizeWithOldSuperviewSize: (NSSize) parameter1;

@end

@interface NSNavSidebarScrollView(NSLiveResizeOptimizations)

- (char) preservesContentDuringLiveResize;

@end

