//
//  JMSidebarView.m
//  PureFTP
//
//  Created by Jean-Matthieu on 25/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "JMSidebarView.h"
#import "UserController.h"
#import <Foundation/Foundation.h>
#import "PureController.h"
#import "defines.h"

#include <sys/types.h>
#include <pwd.h>
#include <unistd.h>


@implementation JMSidebarView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        NSString *activeUser = nil;
        activeUser = [[NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile] objectForKey:PureFTPActiveUser];
        
        if (activeUser != nil) {
            if (![activeUser isEqualToString:@""])
            {
                struct passwd *userInfo = NULL;
                const char *login = [activeUser cString];
                if ((userInfo = getpwnam(login)) != NULL)
                {
                    seteuid(userInfo->pw_uid);
                }
            }
        }
        
	NSOpenPanel *oPanel = [[NSOpenPanel openPanel] retain];
        navView = [[oPanel _navView] retain];
        sidebarScroll = [[[[[[[[navView subviews] objectAtIndex:0] subviews] objectAtIndex:0] subviews] objectAtIndex:0] subviews] objectAtIndex:0];
        sidebar = [[[[[[[[[[[[navView subviews] objectAtIndex:0] subviews] objectAtIndex:0] subviews] objectAtIndex:0] subviews] objectAtIndex:0] subviews] objectAtIndex:0] subviews] objectAtIndex:0];
        //[[sidebarScroll documentView] setEnabled:NO];
		/*NSArray *items = [sidebar _allSidebarItemViews];
		NSEnumerator *anEnum = [items objectEnumerator];
		id item;
		while (item=[anEnum nextObject])
		{
			[[item titleCell] setEnabled:NO];
		}*/
		
        seteuid(0);
		
        [oPanel release];
        [self addSubview:sidebarScroll];
    }
    return self;
}


- (void)dealloc
{
    [navView release];
    [super dealloc];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
    NSRect viewBounds = [self bounds];
    [sidebarScroll setFrame:viewBounds];
    //[sidebarScroll setFrameSize:NSMakeSize(viewBounds.size.width , viewBounds.size.height)];
    [sidebarScroll display];
    [sidebar _adjustWidthsToFit];
}    

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
    NSRect viewBounds = [self bounds];
     [sidebarScroll setFrame:viewBounds];
    //[sidebarScroll setFrameSize:NSMakeSize(viewBounds.size.width , viewBounds.size.height)];
    [sidebarScroll display];
    [sidebar _adjustWidthsToFit];
}

- (void)mouseUp:(NSEvent *)theEvent
{
    //id selectedItem = [sidebar selectedItem];
	SInt32 MacVersion;
	Gestalt(gestaltSystemVersion, &MacVersion);
	NSString *m_path = nil;
	if (MacVersion >= 0x1040){
		NSNavFBENode *selectedNode = [[sidebar selectedItem] node];
		m_path = [selectedNode path];
	} else {
		NSNavNode *selectedNode = [[sidebar selectedItem] node];
		m_path = [[selectedNode originalNode] path];
	}

    //NSLog(m_path);
    [[UserController getInstance] setBrowserPath:m_path];
}


-(NSNavSidebarView *) sidebar
{
    return sidebar;
}

@end
