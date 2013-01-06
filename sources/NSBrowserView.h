//
//  NSBrowserView.h
//  PureFTP
//
//  Created by Jean-Matthieu on 25/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSBrowserView : NSView {
    NSBrowser *fileBrowser;
}

-(NSBrowser *) fileBrowser;

@end
