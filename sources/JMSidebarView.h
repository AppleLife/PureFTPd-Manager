//
//  JMSidebarView.h
//  PureFTP
//
//  Created by Jean-Matthieu on 25/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NSNavView, NSNavSidebarView, NSNavSidebarScrollView, NSNavNode, NSNavFBENode;

@interface JMSidebarView : NSView {
    NSNavView *navView;
    NSNavSidebarScrollView *sidebarScroll;
    NSNavSidebarView *sidebar;
}
-(NSNavSidebarView *) sidebar;

@end
