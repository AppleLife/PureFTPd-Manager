//
//  JMNavSplitView.m
//  PureFTP
//
//  Created by Jean-Matthieu on 25/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "JMNavSplitView.h"



@implementation JMNavSplitView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        fileBrowserView = [[NSBrowserView alloc] initWithFrame:frame];
        
        splitview = [[NSSplitView alloc] initWithFrame:frame];
        [splitview setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        sidebarView = [[JMSidebarView alloc] initWithFrame:NSMakeRect(0,0,130,231)];
        
        [splitview setVertical:YES];
        [splitview addSubview:sidebarView];
        [splitview addSubview:fileBrowserView];
        [splitview adjustSubviews];
        
        [self addSubview:splitview];
        [self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        [sidebarView setFocusRingType:NSFocusRingTypeNone];
    }
    return self;
}

- (void)dealloc
{
    [fileBrowserView release];
    [sidebarView release];
    [splitview release];
    [super dealloc];
}


- (void)drawRect:(NSRect)rect {
    // Drawing code here.
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
    NSRect viewBounds = [self bounds];
    [splitview setFrameSize:NSMakeSize(viewBounds.size.width , viewBounds.size.height)];
    [splitview display];
	//[sidebarView setFocusRingType:NSFocusRingTypeNone];
}   

- (NSBrowser *)fileBrowser
{
    return [fileBrowserView fileBrowser];
}

- (id)sidebar
{
    return [sidebarView sidebar];
}


@end
