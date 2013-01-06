//
//  NSBrowserView.m
//  PureFTP
//
//  Created by Jean-Matthieu on 25/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "NSBrowserView.h"
#import "UserController.h"


#import "FSNodeInfo.h"
#import "FSBrowserCell.h"

#import "NSFileManager+ASExtensions.h"

#define MAX_VISIBLE_COLUMNS 3

@implementation NSBrowserView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        fileBrowser = [[NSBrowser alloc] initWithFrame:frame];
        [fileBrowser setDelegate:[UserController getInstance]];
        [fileBrowser setAcceptsArrowKeys:YES];
        [fileBrowser setAllowsEmptySelection:YES];
        [fileBrowser setTitled:NO];
        [fileBrowser setHasHorizontalScroller:YES];
		
        [fileBrowser setEnabled:NO];
        
        // Make the browser user our custom browser cell.
        [fileBrowser setCellClass: [FSBrowserCell class]];
        
        // Tell the browser to send us messages when it is clicked.
        [fileBrowser setTarget: [UserController getInstance]];
        [fileBrowser setAction: @selector(browserSingleClick:)];
        [fileBrowser setDoubleAction: @selector(browserDoubleClick:)];
        
        // Configure the number of visible columns (default max visible columns is 1).
        [fileBrowser setMaxVisibleColumns: MAX_VISIBLE_COLUMNS];
        [fileBrowser setMinColumnWidth: NSWidth([fileBrowser bounds])/(float)MAX_VISIBLE_COLUMNS];
        [fileBrowser setMinColumnWidth:25];
        [fileBrowser setAutoresizesSubviews:YES];
        
        OSStatus        err;
        UInt32          response;
        err = Gestalt(gestaltSystemVersion, (SInt32 *) &response);
        
        if ( (err == noErr) && (response >= 0x01030) ) {
            [fileBrowser setColumnResizingType:NSBrowserUserColumnResizing];
            [fileBrowser setWidth:150 ofColumn:-1];
            [fileBrowser setColumnsAutosaveName:@"fileBrowserColumns"];
            [fileBrowser setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
			[fileBrowser setFocusRingType:NSFocusRingTypeNone];
        }
        
        [self addSubview:fileBrowser];
        [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    }
    return self;
}

- (void)dealloc
{
    [fileBrowser release];
    [super dealloc];
}


- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
    NSRect viewBounds = [self bounds];
    [fileBrowser setFrameSize:NSMakeSize(viewBounds.size.width , viewBounds.size.height)];
    [fileBrowser display];
	
}   


- (void)drawRect:(NSRect)rect {
    // Drawing code here.
	//[self display];
}

-(NSBrowser *) fileBrowser
{
    return fileBrowser;
}

@end
