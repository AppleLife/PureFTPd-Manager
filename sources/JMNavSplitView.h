//
//  JMNavSplitView.h
//  PureFTP
//
//  Created by Jean-Matthieu on 25/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "JMSidebarView.h"
#import "NSBrowserView.h"

@class NSNavSplitView;

@interface JMNavSplitView : NSView {
    NSBrowserView *fileBrowserView;
    JMSidebarView *sidebarView;
    NSSplitView *splitview;
}

- (NSBrowser *)fileBrowser;
- (id)sidebar;

@end
