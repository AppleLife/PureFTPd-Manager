/*
    PureFTPd Manager
    Copyright (C) 2003-2004 Jean-Matthieu Schaffhauser <jean-matthieu@users.sourceforge.net>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/


#import "PureController.h"


#import <Security/Security.h>
#import "AuthForAllImpl.h"
#import "AuthForAllImplCompat.h"

PureController* thePureController = nil;

@implementation PureController

#pragma mark 
#pragma mark #--==> Initial setup <==--#

+(id) getInstance
{
    // TODO: Mutex Begin
    if (thePureController == nil) {
        thePureController = [[PureController alloc] init];
    }
    // TODO: Mutex End
    return thePureController;
}


-(id) init 
{
    self = [super init];
    if (self)
    {
        thePureController = self;
		
    }
    return self;
}


-(void) setDockMenu
{   
    dockMenu = [[NSMenu alloc] init];
    NSMenuItem *anItem; 
    
    anItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Server Status",@"localized string")
                        action:@selector(showTab:)
                 keyEquivalent:@" "];
    [anItem setTag:10];
    [dockMenu addItem:anItem];
    [anItem release];
    
    anItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Server Logs",@"localized string")
					action:@selector(showTab:)
				 keyEquivalent:@" "];
    [anItem setTag:14];
    
    [dockMenu addItem:anItem];
    [anItem release];
    
    anItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"User Manager",@"localized string")
                   action:@selector(showTab:)
            keyEquivalent:@" "];
    [anItem setTag:11];
    [dockMenu addItem:anItem];
    [anItem release];
    
    anItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Virtual Hosts",@"localized string")
                   action:@selector(showTab:)
            keyEquivalent:@" "];
    [anItem setTag:12];
    [dockMenu addItem:anItem];
    [anItem release];
    
    anItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Preferences",@"localized string")
                                        action:@selector(showTab:)
                                 keyEquivalent:@" "];
    [anItem setTag:13];
    [dockMenu addItem:anItem];
    [anItem release];
    
    [dockMenu addItem:[NSMenuItem separatorItem]];
    
    anItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Start Server",@"localized string")
                   action:@selector(startServer:)
            keyEquivalent:@" "];
    [dockMenu addItem:anItem];
    [anItem release];
       
    anItem = [[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Stop Server",@"localized string")
                   action:@selector(stopServer:)
            keyEquivalent:@" "];
    [dockMenu addItem:anItem];
    [anItem autorelease];
    
    
    
        
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	[window saveFrameUsingName:@"pureftpdmainWindow"];
	NSRect frame = [window frame];
	NSString *frameinfo = [NSString stringWithFormat:@"%f:%f:%f:%f", 
					frame.origin.x, frame.origin.y, frame.size.width, frame.size.height];
	//NSLog(info);
	NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
    [prefs setObject:frameinfo forKey:@"windowsize"];
    [prefs writeToFile:PureFTPPreferenceFile atomically:YES]; 
}

-(void) awakeFromNib
{
    [NSApp setDelegate:self];
    // Switch to front
    [NSApp activateIgnoringOtherApps:YES];
	
	
    thePureController = self;
     prefWinWasVisible = NO;
    fm = [NSFileManager defaultManager];
    if([fm fileExistsAtPath:@"/tmp/PureFTPdManagerUser"])
    {
		activeUser = [[NSString alloc] initWithContentsOfFile:@"/tmp/PureFTPdManagerUser"];
        [fm removeFileAtPath:@"/tmp/PureFTPdManagerUser" handler:nil];
    } 
	
	
	// refresh the auth before it times out -- standard timeout is 300, we refresh the auth every 4 minutes.
	//[NSTimer scheduledTimerWithTimeInterval:240 target:self selector:@selector(refreshAuthorization)  userInfo:nil repeats:YES];
	
    
	SInt32 MacVersion; // remove wrongly placed /etc/xinetd.d/ftp file on 10.4 systems
    Gestalt(gestaltSystemVersion, &MacVersion);
	if ((MacVersion >= 0x1040) && ([fm fileExistsAtPath:@"/etc/xinetd.d/ftp"])){
		[fm removeFileAtPath:@"/etc/xinetd.d/ftp" handler:nil];
	}
	
    [self loadPreferences]; 
    
	
	
    // About
    [creditsTextView setRichText:YES];
    [creditsTextView readRTFDFromFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"credits" ofType:@"rtf"]];
    if(!thePureController)
	{
		thePureController = self;
	}
        
    
    [self setupToolbar];
    [self setDockMenu];
    
    pureFTPD = [[PureFTPD alloc] init];
    statusController = [StatusController getInstance];
    userController = [UserController getInstance];
    vhostManager = [VHostManager getInstance];
    logManager = [LogManager getInstance];
    
    
    
    //Set mainTabView delegate
    [mainTabView setDelegate:self];
    
    
    [vhostTable setTarget:self];
    [vhostTable setDataSource:vhostManager];
    [vhostTable setDelegate:vhostManager];
    [vhostTable reloadData];
        
    if([vhostTable numberOfRows] >=1)
        [self getHostInfoFor:[[vhostManager vhosts] objectAtIndex:0]];
    
	NSString *windowsize = nil;
	
	 if ((windowsize = [[NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile] objectForKey:@"windowsize"]) !=nil)
	 {
		NSArray *frameinfo=[windowsize componentsSeparatedByString:@":"];
		if ([frameinfo count] == 4)
		{
			float x= [[frameinfo objectAtIndex:0] floatValue];
			float y= [[frameinfo objectAtIndex:1] floatValue];
			float w = [[frameinfo objectAtIndex:2] floatValue];
			float h = [[frameinfo objectAtIndex:3] floatValue];
			
			
			NSScreen *screen =  [NSScreen mainScreen];
			NSRect visible = [screen visibleFrame];
			float sx = visible.origin.x;
			float sy = visible.origin.y;
			float sw= visible.size.width;
			float sh= visible.size.height;
			
			if ((x > sw) || (x <sx))
			{
				x = (sw-w)/2;
			}
			
			if ((y > sh) || (y <sy))
			{
				y = (sh-h)/2;
			}
						
			NSRect frame = NSMakeRect(x,y,w,h);
			[window setFrame:frame display:NO];
		}
	 } 
	
	
	[self registerHelp];
	
    [[NSApp mainWindow] makeKeyAndOrderFront:nil];
    showSplash=YES;
    
}

- (void)registerHelp
{
	CFBundleRef myApplicationBundle;
    CFURLRef myBundleURL;
    FSRef myBundleRef;
    OSStatus err = noErr;
 
    myApplicationBundle = NULL;
    myBundleURL = NULL;
 
    myApplicationBundle = CFBundleGetMainBundle();// 1
    if (myApplicationBundle == NULL) {err = fnfErr; return;}
 
    myBundleURL = CFBundleCopyBundleURL(myApplicationBundle);// 2
    if (myBundleURL == NULL) {err = fnfErr; return;}
 
    if (!CFURLGetFSRef(myBundleURL, &myBundleRef)) err = fnfErr;// 3
 
    if (err == noErr) err = AHRegisterHelpBook(&myBundleRef);// 4
    return ;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification{
    
    if ([[aNotification object] isEqualTo:window] && showSplash)
    {
		NSMutableDictionary *pref = [NSMutableDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
		NSString *currentVersionNumber = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"];
		NSString *prefVersion = [pref objectForKey:PureFTPPreferencesVersion];
		
        if (([[pref objectForKey:@"ShowSplashWin"] intValue] == 1) || 
			(prefVersion == nil) || (![currentVersionNumber isEqualToString:prefVersion]))
        {
            NSRect windowFrame = [window frame];
            NSRect donationRect = [donationPanel frame];
            
            [donationPanel setFrameOrigin:NSMakePoint(windowFrame.origin.x+(windowFrame.size.width-donationRect.size.width)/2,windowFrame.origin.y+(windowFrame.size.height-donationRect.size.height)/2)];
            
            [donationPanel makeKeyAndOrderFront:nil];
			[pref setObject:currentVersionNumber forKey:PureFTPPreferencesVersion];
			[pref writeToFile:PureFTPPreferenceFile atomically:YES];
        }
    }
	
    showSplash = NO;
	
}


- (IBAction)splashAction:(id)sender
{
    NSNumber *state = [NSNumber numberWithInt:![sender state]];
    NSMutableDictionary *prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
    [prefs setObject:state forKey:@"ShowSplashWin"];
    [prefs writeToFile:PureFTPPreferenceFile atomically:YES];
    
}



-(void) loadPreferences
{
   
	
	NSDictionary *prefs=nil;
    prefs = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
	NSString *prefVersion = nil;
	prefVersion = [prefs objectForKey:PureFTPPreferencesVersion];
			
    if ( (prefs == nil) || (![[prefs objectForKey:@"wizardCompleted"] isEqualToString:@"Done"]) ||
		 (prefVersion == nil) /*|| (![currentVersionNumber isEqualToString:prefVersion])*/ )
    {
        [self launchAssistant:nil];
    } 
	
    // Check for new version 
    if ([[prefs objectForKey:PureFTPAutoUpdate] intValue] == 1)
    {
        [NSThread detachNewThreadSelector:@selector(newVersionThread:) toTarget:self withObject:@"AutoUpdate"];
    }

}

-(void)dealloc
{
    [pureFTPD release];
    [toolbarItems release];
    [toolbar release];
	if(activeUser)
		[activeUser release];
    if (preferencesController != nil)
        [[self preferencesController] release];
    [super dealloc];
}

- (NSMenu *)applicationDockMenu:(NSApplication *)sender
{
    return dockMenu;
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification
{
    /*if (prefWinWasVisible == YES){
        [[preferencesController window] orderFront:nil];
        [[preferencesController window] setAlphaValue:1.0];
        prefWinWasVisible = NO;
    }
    [window setAlphaValue:1.0];*/
	
    //[window makeKeyAndOrderFront:nil];
    
}


- (void)applicationDidResignActive:(NSNotification *)aNotification
{
    //[self makeTranslucent];
}

- (BOOL)windowShouldClose:(id)sender
{
    [NSApp hide:nil];
    return NO;
}

- (MVPreferencesController *)preferencesController 
{ 
    if (!preferencesController) {
        preferencesController = [[MVPreferencesController sharedInstance] retain];
    }
    return preferencesController; 
}

- (void)makeTranslucent
{
    if (![window isVisible])
        return;
    
    //[window orderBack:nil];
    [window setAlphaValue:0.5];
    
    if([[preferencesController window] isVisible])
    {
        prefWinWasVisible = YES;
        //[[preferencesController window] orderBack:nil];
        [[preferencesController window] setAlphaValue:0.5];
    }
}


#pragma mark 
#pragma mark #--==> Toolbar setup <==--#

-(void) setupToolbar
{
	toolbarItems = [[NSMutableDictionary alloc] init];

	NSToolbarItem *item;

	item = [[NSToolbarItem alloc] initWithItemIdentifier:@"pureftpd.status"];
	[item setPaletteLabel:NSLocalizedString(@"Server Status",@"localized string")];
	[item setLabel:NSLocalizedString(@"Server Status",@"localized string")];
	[item setToolTip:NSLocalizedString(@"View Server Status",@"localized string")];
        [item setImage: [NSImage imageNamed: @"status"]];
	[item setTarget:self];
	[item setAction:@selector(showTab:)];
	[toolbarItems setObject:item forKey:@"pureftpd.status"];
	[item release];
	
	item = [[NSToolbarItem alloc] initWithItemIdentifier:@"pureftpd.logging"];
	[item setPaletteLabel:NSLocalizedString(@"Server Logs",@"localized string")];
	[item setLabel:NSLocalizedString(@"Server Logs",@"localized string")];
	[item setToolTip:NSLocalizedString(@"View Server Logs",@"localized string")];
        [item setImage: [NSImage imageNamed: @"logging"]];
	[item setTarget:self];
	[item setAction:@selector(showTab:)];
	[toolbarItems setObject:item forKey:@"pureftpd.logging"];
	[item release];

	item = [[NSToolbarItem alloc] initWithItemIdentifier:@"pureftpd.users"];
	[item setPaletteLabel:NSLocalizedString(@"User Manager",@"localized string")];
	[item setLabel:NSLocalizedString(@"User Manager",@"localized string")];
	[item setToolTip:NSLocalizedString(@"Go to User Manager",@"localized string")];
        [item setImage: [NSImage imageNamed: @"users"]];
	[item setTarget:self];
	[item setAction:@selector(showTab:)];
	[toolbarItems setObject:item forKey:@"pureftpd.users"];
	[item release];

	item = [[NSToolbarItem alloc] initWithItemIdentifier:@"pureftpd.hosts"];
	[item setPaletteLabel:NSLocalizedString(@"Virtual Hosts",@"localized string")];
	[item setLabel:NSLocalizedString(@"Virtual Hosts",@"localized string")];
	[item setToolTip:NSLocalizedString(@"Go to Virtual Hosts",@"localized string")];
	[item setImage: [NSImage imageNamed: @"vhosts"]];
	[item setTarget:self];
	[item setAction:@selector(showTab:)];
	[toolbarItems setObject:item forKey:@"pureftpd.hosts"];
	[item release];
        
        item = [[NSToolbarItem alloc] initWithItemIdentifier:@"pureftpd.preferences"];
	[item setPaletteLabel:NSLocalizedString(@"Preferences",@"localized string")];
	[item setLabel:NSLocalizedString(@"Preferences",@"localized string")];
	[item setToolTip:NSLocalizedString(@"Open Preferences",@"localized string")];
        [item setImage: [NSImage imageNamed: @"preferences"]];
	[item setTarget:self];
	[item setAction:@selector(showTab:)];
	[toolbarItems setObject:item forKey:@"pureftpd.preferences"];
	[item release];
        
        item = [[NSToolbarItem alloc] initWithItemIdentifier:@"pureftpd.new"];
	[item setPaletteLabel:NSLocalizedString(@"New Button",@"localized string")];
	[item setLabel:NSLocalizedString(@"New",@"New")];
	[item setToolTip:NSLocalizedString(@"New",@"New")];
        [item setImage: [NSImage imageNamed: @"new"]];
        [item setTag:100];
	[item setTarget:self];
	[item setAction:@selector(selectAddAction:)];
	[toolbarItems setObject:item forKey:@"pureftpd.new"];
	[item release];
        
        item = [[NSToolbarItem alloc] initWithItemIdentifier:@"pureftpd.delete"];
	[item setPaletteLabel:NSLocalizedString(@"Delete Button",@"localized string")];
	[item setLabel:NSLocalizedString(@"Delete",@"Delete")];
	[item setToolTip:NSLocalizedString(@"Delete",@"Delete")];
        [item setImage: [NSImage imageNamed: @"delete"]];
        [item setTag:102];
	[item setTarget:self];
	[item setAction:@selector(selectDeleteAction:)];
	[toolbarItems setObject:item forKey:@"pureftpd.delete"];
	[item release];
        
        item = [[NSToolbarItem alloc] initWithItemIdentifier:@"pureftpd.save"];
	[item setPaletteLabel:NSLocalizedString(@"Save",@"Save")];
	[item setLabel:NSLocalizedString(@"Save",@"Save")];
	[item setToolTip:NSLocalizedString(@"Save",@"Save")];
        [item setImage: [NSImage imageNamed: @"save"]];
        [item setTag:101];
	[item setTarget:self];
	[item setAction:@selector(selectSaveAction:)];
	[toolbarItems setObject:item forKey:@"pureftpd.save"];
	[item release];
        
        item = [[NSToolbarItem alloc] initWithItemIdentifier:@"pureftpd.refresh"];
	[item setPaletteLabel:NSLocalizedString(@"Refresh",@"localized string")];
	[item setLabel:NSLocalizedString(@"Refresh",@"localized string")];
	[item setToolTip:NSLocalizedString(@"Refresh",@"localized string")];
        [item setImage: [NSImage imageNamed: @"refresh"]];
	[item setTarget:self];
	[item setAction:@selector(refreshContents:)];
	[toolbarItems setObject:item forKey:@"pureftpd.refresh"];
	[item release];
        
        toolbar = [[NSToolbar alloc] initWithIdentifier:@"toolbar"];
	[toolbar setDelegate:self];
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	[window setToolbar:toolbar];
}


#pragma mark 
#pragma mark #--==> Toolbar delegates <==--#

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
	NSArray *arr = [[NSArray alloc] initWithObjects:@"pureftpd.status", @"pureftpd.logging",  NSToolbarSeparatorItemIdentifier, 
	                                            @"pureftpd.users", @"pureftpd.hosts", NSToolbarSeparatorItemIdentifier, 
                                                    @"pureftpd.new", @"pureftpd.save", @"pureftpd.delete", 
                                                    NSToolbarFlexibleSpaceItemIdentifier, @"pureftpd.preferences", 
                                                    @"pureftpd.refresh", nil];
	[arr autorelease];
	return arr;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
	NSArray *arr = [[NSArray alloc] initWithObjects:@"pureftpd.status", @"pureftpd.users",
                                                    @"pureftpd.hosts", @"pureftpd.preferences", 
                                                    @"pureftpd.new", @"pureftpd.delete", @"pureftpd.save", @"pureftpd.refresh",
                                                    NSToolbarSeparatorItemIdentifier, NSToolbarSpaceItemIdentifier,
                                                    NSToolbarFlexibleSpaceItemIdentifier, nil];
	[arr autorelease];
	return arr;
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar itemForItemIdentifier:(NSString *)identifier willBeInsertedIntoToolbar:(BOOL)flag
{
	return [toolbarItems objectForKey:identifier];
}

- (BOOL)validateToolbarItem:(NSToolbarItem *)item
{
    NSString *key = [item itemIdentifier];
    NSTabViewItem *tab;
    tab = [mainTabView selectedTabViewItem];
    
    if ([key isEqualToString:@"pureftpd.new"]){ 
		if ([[tab identifier] hasSuffix:@"status"] || [[tab identifier] hasSuffix:@"logging"]){
			[item setToolTip:@""];
			return NO;
		} else if ([[tab identifier] hasSuffix:@"users"]){
			[item setToolTip:NSLocalizedString(@"Create a new Virtual User",@"Create a new Virtual User")];
		} else if ([[tab identifier] hasSuffix:@"hosts"]){
			[item setToolTip:NSLocalizedString(@"Create a new Virtual Host",@"Create a new Virtual Host")];
		}
	}
        
    if ([key isEqualToString:@"pureftpd.save"]) {
        if([[tab identifier] hasSuffix:@"status"] || [[tab identifier] hasSuffix:@"logging"]){
            [item setToolTip:@""];
			return NO;
        }else if ([[tab identifier] hasSuffix:@"users"] ){
			[item setToolTip:NSLocalizedString(@"Save Virtual User", @"Save Virtual User")];
			
            if([[userController currentUser] hasBeenEdited])
                return YES;
            else
                return NO;
        }
        else if ([[tab identifier] hasSuffix:@"hosts"]) {
			[item setToolTip:NSLocalizedString(@"Save Virtual Host", @"Save Virtual Host")];
			if (![vhostManager areVhostsModified])
				return NO;
		}
    }
    
    if ([key isEqualToString:@"pureftpd.delete"]){
        if ([[tab identifier] hasSuffix:@"status"]){
			[item setToolTip:@""];
            return NO;
        } else if([[tab identifier] hasSuffix:@"logging"]) {
			[item setToolTip:NSLocalizedString(@"Delete Log History", @"Delete Log History")];
			if ([[logManager usersTable] selectedRow] == -1)
				return NO;
        } else if ([[tab identifier] hasSuffix:@"users"]){
			[item setToolTip:NSLocalizedString(@"Delete Virtual User", @"Delete Virtual User")];
			if ([[userController userTable] selectedRow] == -1)
				return NO;
        } else if ([[tab identifier] hasSuffix:@"hosts"]){ 
			[item setToolTip:NSLocalizedString(@"Delete Virtual Host", @"Delete Virtual Host")];
			if ([[vhostManager vhosts] count] < 1)
				return NO;
        }
    }
    
    if ([key isEqualToString:@"pureftpd.refresh"]){ 
        if ([[tab identifier] hasSuffix:@"users"] || [[tab identifier] hasSuffix:@"hosts"]) {
			[item setToolTip:@""];
			return NO;
		} else if ([[tab identifier] hasSuffix:@"status"]){
			[item setToolTip:NSLocalizedString(@"Refresh Status", @"Refresh Status")];
		} else if ([[tab identifier] hasSuffix:@"logging"]){
			[item setToolTip:NSLocalizedString(@"Refresh Logs", @"Refresh Logs")];
		}
    }
    return YES;
}

#pragma mark 
#pragma mark #--==> Menu items Validation <==--#

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    //NSString *key = [item title];
    int tag = [item tag];
    NSTabViewItem *tab;
    tab = [mainTabView selectedTabViewItem];
    
    if ((tag == 100) && ([[tab identifier] hasSuffix:@"status"]))
        return NO;
        
    if (tag == 101) {
        if([[tab identifier] hasSuffix:@"status"])
            return NO;
        else if ([[tab identifier] hasSuffix:@"users"] && ![[userController currentUser] hasBeenEdited])
            return NO;
        else if ([[tab identifier] hasSuffix:@"hosts"] && ![vhostManager areVhostsModified])
            return NO;
    }
    
    if (tag == 102){
        if ([[tab identifier] hasSuffix:@"status"])
            return NO;
        else if(([[tab identifier] hasSuffix:@"logging"]) && ([[logManager usersTable] selectedRow] == -1))
            return NO;
        else if ([[tab identifier] hasSuffix:@"users"] && ([[userController userTable] selectedRow] == -1))
            return NO;
        else if ([[tab identifier] hasSuffix:@"hosts"] && ([[vhostManager vhosts] count] < 1))
            return NO;
    }
    
    return YES;
}

-(IBAction) launchAssistant:(id)sender 
{
    
    int ret = 0;
    if ([sender isKindOfClass:[NSString class]]){
        if ([sender isEqualToString:@"asktoconfirm"])
        {
            ret = NSRunAlertPanel(NSLocalizedString(@"Do you want to start the Setup Assistant now ?",@"Do you want to start the Setup Assistant now ?"), 
                                  NSLocalizedString(@"You must quit PureFTPd Manager to continue. Are you sure you want to do this ?",@"You must quit PureFTPd Manager to continue. Are you sure you want to do this ?"), NSLocalizedString(@"Cancel",@"Cancel"),
                                  NSLocalizedString(@"Continue",@"Continue"), nil);
            if (ret==NSAlertDefaultReturn)
                return;
        }
    }
    
    NSString *bundleParent = [[NSBundle mainBundle] resourcePath];
    
    NSTask *manager = [[NSTask alloc] init];
    [manager setLaunchPath:[bundleParent stringByAppendingPathComponent:@"PureFTPd Manager Setup Assistant.app/Contents/MacOS/PureFTPd Manager Setup Assistant"]];
    [manager launch];
    [manager release];
    
    [NSApp terminate:self];
}

-(IBAction) pdfHelp:(id)sender
{
	NSString *locBookName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleHelpBookName"];
	
	NSString *path=[[NSBundle mainBundle] pathForResource:@"index" ofType:@"html" inDirectory:locBookName];
	[[NSWorkspace sharedWorkspace] openFile:path];
	
}

-(IBAction) gotoPayPalWithAmount:(id)sender
{
	NSString *amount=nil;
	int selectedAmount = [donationPopUp indexOfSelectedItem];
	switch (selectedAmount){
		case 0:
			amount=@"5";
			break;
		case 1:
			amount=@"10";
			break;
		case 2:
			amount=@"15";
			break;
		case 3:
			amount=@"20";
			break;
		case 4:
			amount=@"42";
			break;
		case 5:
			amount=nil;
			break;
		default:
			amount = nil;
			break;
	}
	NSString *url=nil;
	if (amount == nil){
		url = @"https://www.paypal.com/xclick/business=jms@supinfo.com&item_name=PureFTPd+Manager&no_note=1&tax=0&currency_code=EUR&lc=US";
	}else {
		url = [NSString stringWithFormat:@"https://www.paypal.com/xclick/business=jms@supinfo.com&item_name=PureFTPd+Manager&no_note=1&tax=0&currency_code=EUR&lc=US&amount=%@", amount];
	}
	
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
	[donationPanel orderOut:nil];
}

-(IBAction) gotoPayPal:(id)sender 
{
    [[NSWorkspace sharedWorkspace] openURL:
        [NSURL URLWithString:@"https://www.paypal.com/xclick/business=jms@supinfo.com&item_name=PureFTPd+Manager&no_note=1&tax=0&currency_code=EUR&lc=US"]];
}

-(IBAction) checkForNewVersion:(id)sender 
{
    [NSThread detachNewThreadSelector:@selector(newVersionThread:) toTarget:self withObject:nil ];
}

-(void) newVersionThread:(id)sender
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    NSString *currVersionNumber = [[[NSBundle bundleForClass:[self class]] infoDictionary] objectForKey:@"CFBundleVersion"];
    BOOL showAlert = YES;
    
    if ([sender isEqualToString:@"AutoUpdate"])
        showAlert=NO;
    
    NSDictionary *productVersionDict = nil;
    productVersionDict = [NSDictionary dictionaryWithContentsOfURL:
                                        [NSURL URLWithString:@"http://jeanmatthieu.free.fr/pureftpd/pkg/updates.xml"]];
    
    if (productVersionDict == nil)
    {
        if(showAlert){
        NSBeginAlertSheet(NSLocalizedString(@"Connection error",
                                            @"Title of alert when there is a connection error during update process."),
                          NSLocalizedString(@"OK", @"OK"),nil, nil, window,
                          nil, nil, nil, nil,
                          NSLocalizedString(@"Unable to connect to the upgrade server.\nPlease check your internet link status and try again.",
                                            @"Alert text when an error occur during upgrade."));
        } else {
            //NSLog(@"PureFTPd Manager AutoUpdate : Unable to connect to the upgrade server.");
        }
        [pool release];
        //[NSThread exit];
        return;
    }
    
    NSString *latestVersionNumber = [productVersionDict valueForKey:@"latest"];
    NSString *urlVersion = [NSString stringWithFormat:@"http://jeanmatthieu.free.fr/pureftpd/pkg/changelog-%@.rtf", latestVersionNumber];
    NSURL *changeLogURL = [NSURL URLWithString:urlVersion];
    
    if(([latestVersionNumber isEqualTo: currVersionNumber]))
    {
        if(showAlert){
        NSBeginAlertSheet(NSLocalizedString(@"PureFTPd Manager is up-to-date",
                                         @"Title of alert when a the user's software is up to date."),
                                         NSLocalizedString(@"OK", @"OK"),nil, nil, window,
                                        nil, nil, nil, nil,
                       NSLocalizedString(@"You have the latest version of PureFTPd Manager.",
                                         @"Alert text when the user's software is up to date."));
        } else {
            //NSLog(@"PureFTPd Manager AutoUpdate : You have the latest version of PureFTPd Manager.");
        }
    }
    else
    {
//        [changeLog replaceCharactersInRange:NSMakeRange(0, 0) withString:@""];
        [changeLog setString:@""];
        NSData *fileData = [NSData dataWithContentsOfURL:changeLogURL];
        if (fileData != nil)
            [changeLog replaceCharactersInRange:NSMakeRange(0, 0) withRTF:fileData];
        
        [updatePanel makeKeyAndOrderFront:nil];
        [versionNumber setStringValue:latestVersionNumber];
    }
	
    [pool release];
    //[NSThread exit];
    
}



-(IBAction) upgradeNow:(id)sender 
{
    [[NSWorkspace sharedWorkspace] openURL:
        [NSURL URLWithString:@"http://jeanmatthieu.free.fr/pureftpd/download.html"]];
    [updatePanel performClose:nil];
    
}


#pragma mark 
#pragma mark #--==> Toolbar actions <==--#

-(void) showTab:(id)sender
{    
    if ([sender isKindOfClass:[NSMenuItem class]])
    {
        switch ([sender tag]) {
            case 10:
                [mainTabView selectTabViewItemWithIdentifier:@"pureftpd.status"];
                break;
            case 11:
                [mainTabView selectTabViewItemWithIdentifier:@"pureftpd.users"];
                break;
            case 12:
                [mainTabView selectTabViewItemWithIdentifier:@"pureftpd.hosts"];
                break;
            case 13:
                 [[self preferencesController] showPreferences:nil] ;
                break;
	    case 14:
                [mainTabView selectTabViewItemWithIdentifier:@"pureftpd.logging"];
                break;
        }
    }
    else if ([[sender itemIdentifier] hasSuffix:@"preferences"])
        [[self preferencesController] showPreferences:nil] ;
    else
        [mainTabView selectTabViewItemWithIdentifier:[sender itemIdentifier]];
}

-(void) startServer:(id)sender
{
    [statusController startServer:nil];
}

-(void) stopServer:(id)sender
{
    [statusController stopServer:nil];
}


-(void)selectAddAction:(id)sender
{
    if([[[mainTabView selectedTabViewItem] identifier] isEqualToString:@"pureftpd.users"]){
        [userController createUser];
    }else if([[[mainTabView selectedTabViewItem] identifier] isEqualToString:@"pureftpd.hosts"]){
        [vhostManager addEmptyHost];
    }
}

-(void)selectDeleteAction:(id)sender
{
    if([[[mainTabView selectedTabViewItem] identifier] isEqualToString:@"pureftpd.users"]){
        [userController deleteUser];
    }else if([[[mainTabView selectedTabViewItem] identifier] isEqualToString:@"pureftpd.logging"]){
        [logManager clearLog:nil];
    }else if([[[mainTabView selectedTabViewItem] identifier] isEqualToString:@"pureftpd.hosts"]){
        [vhostManager deleteHost];
    }
}

-(void)selectSaveAction:(id)sender
{
    if([[[mainTabView selectedTabViewItem] identifier] isEqualToString:@"pureftpd.users"]){ 
        [userController saveUser];
    }
    if([[[mainTabView selectedTabViewItem] identifier] isEqualToString:@"pureftpd.hosts"])    
        [vhostManager savetoPreferences];
}


-(void)refreshContents:(id)sender
{
   
    if([[[mainTabView selectedTabViewItem] identifier] isEqualToString:@"pureftpd.status"])
        [statusController refreshStatus:nil]; 
    else if ([[[mainTabView selectedTabViewItem] identifier] isEqualToString:@"pureftpd.logging"])
        [logManager refreshAction:nil];
}


#pragma mark
#pragma mark #--==> Choose buttons actions <==--#
- (IBAction)chooseDir:(id)sender
{
    
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	if ([oPanel respondsToSelector:@selector(setCanCreateDirectories:)])
		[oPanel setCanCreateDirectories:YES];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:NO];
    [oPanel setResolvesAliases:NO];
    
    [oPanel beginSheetForDirectory:NSHomeDirectoryForUser([self activeUser]) file:nil types:nil 
                       modalForWindow:[NSApp mainWindow]
                       modalDelegate: self
                       didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo: (void *)[sender tag]];
    
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
    [NSApp stopModal];
    if (returnCode == NSOKButton && ((int)contextInfo==200)){
        [vhostDirField setStringValue: [[sheet filenames] objectAtIndex:0]];
        [vhostManager setModified:YES];
    }
}


#pragma mark 
#pragma mark #--==> Vhosts fields <==--#

-(void) getHostInfoFor:(NSMutableDictionary *)infoDict
{
    [vhostNameField setStringValue:[infoDict objectForKey:@"vhost.name"]];
    [vhostIPField setStringValue:[infoDict objectForKey:@"vhost.ip"]];
    [vhostNICPopUp selectItemWithTitle:[infoDict objectForKey:@"vhost.nic"]];
    [vhostDirField setStringValue:[infoDict objectForKey:@"vhost.dir"]];
}

-(void) disableHostFields
{
    [self clearHostFields];
    [vhostNameField setEnabled:NO];
    [vhostIPField setEnabled:NO];
    [vhostNICPopUp setEnabled:NO];
    [vhostDirField setEnabled:NO];
    [chooseVHostDirButton setEnabled:NO];
}

-(void)enableHostFields
{
    [vhostNameField setEnabled:YES];
    [vhostIPField setEnabled:YES];
    [vhostNICPopUp setEnabled:YES];
    [vhostDirField setEnabled:YES];
    [chooseVHostDirButton setEnabled:YES];
}

-(void) clearHostFields
{
    [vhostNameField setStringValue:@""];
    [vhostIPField setStringValue:@""];
    [vhostNICPopUp selectItemWithTitle:@"en0"];
    [vhostDirField setStringValue:@""];
}

-(NSTableView *)vhostTable
{
    return vhostTable;
}

-(NSTextField *)vhostDirField
{
    return vhostDirField;
}
-(NSTextField *)vhostIPField
{
    return vhostIPField;
}

-(NSTextField *)vhostNameField
{
    return vhostNameField;
}
-(NSPopUpButton *)vhostNICPopUp
{
    return vhostNICPopUp;
}

#pragma mark 
#pragma mark #--==> Main tabview delegates <==--#

- (void) setSelectNow:(BOOL)opt
{
    selectNow=opt;
}

-(BOOL) selectNow
{
    return selectNow;
}

- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    NSTabViewItem *currentTabViewItem = [tabView selectedTabViewItem];
    selectNow = NO;
    if([[currentTabViewItem identifier] isEqualToString:@"pureftpd.users"] && 
        [[userController currentUser] hasBeenEdited]) //Save before changing tab
        {
            [userController saveAlert];
            return selectNow;
        }
        
     
     if([[currentTabViewItem identifier] isEqualToString:@"pureftpd.hosts"] &&
        [vhostManager areVhostsModified])
        {
            [vhostManager saveAlert];
            return selectNow;
        }
        
    return YES;
}

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
    if([[tabViewItem identifier] isEqualToString:@"pureftpd.status"])
        [window setTitle:NSLocalizedString(@"PureFTPd Manager - Server Status",@"localized string")];
    else if([[tabViewItem identifier] isEqualToString:@"pureftpd.logging"])                
        [window setTitle:NSLocalizedString(@"PureFTPd Manager - Server Logs",@"localized string")];
    else if([[tabViewItem identifier] isEqualToString:@"pureftpd.users"])                
        [window setTitle:NSLocalizedString(@"PureFTPd Manager - User Manager",@"localized string")];
    else if([[tabViewItem identifier] isEqualToString:@"pureftpd.hosts"])
        [window setTitle:NSLocalizedString(@"PureFTPd Manager - Virtual Hosts",@"localized string")];
}


- (NSTabView *)mainTabView
{
    return mainTabView;
}

- (NSString *)activeUser
{
	return activeUser;
}


/*- (void)refreshAuthorization
{
	OSStatus        err;
    UInt32          response;
	err = Gestalt(gestaltSystemVersion, (SInt32 *) &response);
	NSString *infoMsg = NSLocalizedString(@"Next message in your Console originating from com.apple.SecurityServer is safe.", 
	@"Next message in your Console originating from com.apple.SecurityServer is safe.");
    
	NSLog(infoMsg);
	
    if ( (err == noErr) && (response >= 0x01030) ) {
        err = SetupAuthorization();
		if (err != noErr)
		{
			NSLog(@"SetupAuthorization: %d", err);
		}
        err = AcquireRight(kRightName);
		if (err != noErr)
		{
			NSLog(@"AcquireRight: %d", err);
		}
	} else if (err == noErr){
        err = CompatSetupAuthorization();
        err = CompatAcquireRight(CompatkRightName);
    }
}*/

@end
