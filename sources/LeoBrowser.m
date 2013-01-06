//
//  LeoBrowser.m
//  PureFTP
//
//  Created by Jean-Matthieu Schaffhauser on 23/08/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "LeoBrowser.h"

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

@implementation LeoBrowser

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code here.
		[self setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
		
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
					
                    if(seteuid(userInfo->pw_uid) != 0)
						NSLog(@"error on seteuid");
					else 
						NSLog(@"seteuid sucess");
					//setuid(userInfo->pw_uid);
                }
            }
        }

		NSOpenPanel *oPanel = [NSOpenPanel openPanel];
		[oPanel setCanChooseFiles:NO];
		[oPanel setAllowsMultipleSelection:YES];
		[oPanel setDirectory:NSHomeDirectory()];
		[oPanel setCanCreateDirectories:YES];
		[oPanel setCanChooseDirectories:YES];
		
		NSNavView *_navView = [oPanel _navView];
		[_navView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
		[_navView setFrame:frame];
		[self addSubview:_navView];
		
		//seteuid(0);
		//setuid(0);
		
    }
    return self;
}

- (void)drawRect:(NSRect)rect {
    // Drawing code here.
}

@end
