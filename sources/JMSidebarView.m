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

#import "NSNavView.h"
#import "NSNavSidebarView.h"
#import "NSNavSidebarScrollView.h"
#import "NSNavNode.h"
#import "NSNavFBENode.h"
#import "NSNavBrowserCell.h"

#import "PureController.h"

@interface NSOpenPanel (ApplePrivate)
- (NSNavView *)_navView;
@end

@interface NSNavNode (ApplePrivate_103)
- (NSNavFBENode *)originalNode;
@end


@implementation JMSidebarView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
        NSString *activeUser = nil;
         if([[NSFileManager defaultManager] fileExistsAtPath:@"/tmp/PureFTPdManagerUser"])
		{
			activeUser = [NSString stringWithContentsOfFile:@"/tmp/PureFTPdManagerUser"];
		}  else {
			activeUser = [[PureController getInstance] activeUser];
		}
        
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
		setuid(0);
        
		[oPanel release];
		[sidebarScroll setFocusRingType:NSFocusRingTypeNone];
		[sidebar setFocusRingType:NSFocusRingTypeNone];
        [self addSubview:sidebarScroll];
		[self setPostsFrameChangedNotifications:YES];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(frameDidChange:) name:NSViewFrameDidChangeNotification object:nil];
    }
    return self;
}


- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSViewFrameDidChangeNotification object:self];
    [navView release];
    [super dealloc];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldBoundsSize
{
    NSRect viewBounds = [self bounds];
    [sidebarScroll setFrame:viewBounds];
	[sidebarScroll setFocusRingType:NSFocusRingTypeNone];
	[sidebar setFocusRingType:NSFocusRingTypeNone];
	//[sidebarScroll setFrameSize:NSMakeSize(viewBounds.size.width , viewBounds.size.height)];
    //[sidebarScroll display];
    //[sidebar _adjustWidthsToFit];
}    

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
    NSRect viewBounds = [self bounds];
	[sidebarScroll setFrame:viewBounds];
	[sidebarScroll setFocusRingType:NSFocusRingTypeNone];
	[sidebar setFocusRingType:NSFocusRingTypeNone];
    //[sidebarScroll setFrameSize:NSMakeSize(viewBounds.size.width , viewBounds.size.height)];
    //[sidebarScroll display];
    //[sidebar _adjustWidthsToFit];
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

- (void)frameDidChange:(NSNotification *)notif
{
	[[self window] makeFirstResponder:nil];
}

@end
