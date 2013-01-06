/*
 PureFTPd Manager
 Copyright (C) 2003-2004 Jean-Matthieu Schaffhauser <jean-matthieu@users.sourceforge.net>
 
 THIS CODE HAS BEEN BORROWED FROM FIRE.APP (at least I think so)
 I Can't find the guys who coded that in the first place ... If you know, let me know.
 
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

#import <PreferencePanes/PreferencePanes.h>
#import "MVPreferencesController.h"
#import "MVPreferencesMultipleIconView.h"
#import "MVPreferencesGroupedIconView.h"
#import "NSToolbarAdditions.h"

#import "defines.h"


static MVPreferencesController *sharedInstance = nil;

static NSString *MVToolbarShowAllItemIdentifier = @"MVToolbarShowAllItem";
NSString *MVPreferencesWindowNotification = @"MVPreferencesWindowNotification";

@interface NSToolbar (NSToolbarPrivate)
- (NSView *) _toolbarView;
@end

@interface MVPreferencesController (MVPreferencesControllerPrivate)
- (void) _doUnselect:(NSNotification *) notification;
- (IBAction) _selectPreferencePane:(id) sender;
- (void) _resizeWindowForContentView:(NSView *) view;
- (NSImage *) _imageForPaneBundle:(NSBundle *) bundle;
- (NSString *) _paletteLabelForPaneBundle:(NSBundle *) bundle;
- (NSString *) _labelForPaneBundle:(NSBundle *) bundle;
@end

@implementation MVPreferencesController

+ (MVPreferencesController *) sharedInstance
{
	return ( sharedInstance ? sharedInstance : [[[self alloc] init] autorelease] );
}

+ (MVPreferencesController *) sharedInstanceWithParent:(id)parent {
	if (sharedInstance){
		return sharedInstance;
	}
	else {
		sharedInstance = [[[self alloc] init] autorelease];
		[sharedInstance setParent:parent];
	}
	
	return sharedInstance;
    //return ( sharedInstance ? sharedInstance : [[[self alloc] init] autorelease] );
}


- (void)setParent:(id)p
{
	parent = p;
}

- (id) init {
	if( ( self = [super init] ) ) {
		unsigned i = 0;
		NSBundle *bundle = nil;
		NSString *bundlePath = [NSString stringWithFormat:@"%@/Contents/PreferencePanes", [[NSBundle mainBundle] bundlePath]];
		panes = [[[NSFileManager defaultManager] directoryContentsAtPath:bundlePath] mutableCopy];
		for( i = 0; i < [panes count]; i++ ) {
			bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"%@/%@", bundlePath, [panes objectAtIndex:i]]];
			[bundle load];
			if( bundle ) [panes replaceObjectAtIndex:i withObject:bundle];
			else {
				[panes removeObjectAtIndex:i];
				i--;
			}
		}
		loadedPanes = [[NSMutableDictionary dictionary] retain];
		paneInfo = [[NSMutableDictionary dictionary] retain];
		[NSBundle loadNibNamed:@"MVPreferences" owner:self];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector( _doUnselect: ) name:NSPreferencePaneDoUnselectNotification object:nil];
                
		// Default User Dictionaries. We create them here the first time.
		theDefaults = [NSUserDefaults standardUserDefaults];
        mainsrv=[[PureFTPD alloc] init];

                
        }
	return self;
}

- (void) dealloc {

    [mainsrv release];
    [loadedPanes autorelease];
    [panes autorelease];
    [paneInfo autorelease];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    loadedPanes = nil;
    panes = nil;
    paneInfo = nil;
    [super dealloc];
}

- (void) awakeFromNib {
        
        NSToolbar *toolbar = [[[NSToolbar alloc] initWithIdentifier:@"preferences.toolbar"] autorelease];
	NSArray *groups = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MVPreferencePaneGroups" ofType:@"plist"]];

	if( groups ) {
		[groupView setPreferencePanes:panes];
		[groupView setPreferencePaneGroups:groups];
		mainView = groupView;
	} else {
		[multiView setPreferencePanes:panes];
		mainView = multiView;
	}
	[self showAll:nil];

        
        
        
	[window setDelegate:self];
        
	[toolbar setAllowsUserCustomization:YES];
	[toolbar setAutosavesConfiguration:YES];
	[toolbar setDelegate:self];
	[toolbar setAlwaysCustomizableByDrag:YES];
	[toolbar setShowsContextMenu:NO];
    [window setToolbar:toolbar];
	[toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];
	[toolbar setIndexOfFirstMovableItem:2];
                
}

- (NSWindow *) window {
	return [[window retain] autorelease];
}

- (IBAction) showPreferences:(id) sender {
	[self showAll:nil];
	[window makeKeyAndOrderFront:nil];
}

- (IBAction) showAll:(id) sender {
	if( [[window contentView] isEqual:mainView] ) return;
	if( currentPaneIdentifier && [[loadedPanes objectForKey:currentPaneIdentifier] shouldUnselect] != NSUnselectNow ) {
		/* more to handle later */
		//NSLog( @"can't unselect current" );
		closeWhenPaneIsReady = NO;
		[pendingPane autorelease];
		pendingPane = [@"" retain];
		return;
	}
	[window setContentView:[[[NSView alloc] initWithFrame:[mainView frame]] autorelease]];

	[window setTitle:[NSString stringWithFormat:NSLocalizedString( @"%@ Preferences", @"CFBundleName Preferences" ), [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]]];
	[self _resizeWindowForContentView:mainView];

	[[loadedPanes objectForKey:currentPaneIdentifier] willUnselect];
	[window setContentView:mainView];
	[[loadedPanes objectForKey:currentPaneIdentifier] didUnselect];

	[currentPaneIdentifier autorelease];
	currentPaneIdentifier = nil;

	[window setInitialFirstResponder:mainView];
	[window makeFirstResponder:mainView];
}

- (void) selectPreferencePaneByIdentifier:(NSString *) identifier {
	NSBundle *bundle = [NSBundle bundleWithIdentifier:identifier];
	if( bundle && ! [currentPaneIdentifier isEqualToString:identifier] ) {
		NSPreferencePane *pane = nil;
		NSView *prefView = nil;
		if( currentPaneIdentifier && [[loadedPanes objectForKey:currentPaneIdentifier] shouldUnselect] != NSUnselectNow ) {
			/* more to handle later */
			//NSLog( @"can't unselect current" );
			closeWhenPaneIsReady = NO;
			[pendingPane autorelease];
			pendingPane = [identifier retain];
			return;
		}
		[pendingPane autorelease];
		pendingPane = nil;
		[loadingImageView setImage:[self _imageForPaneBundle:bundle]];
		[loadingTextFeld setStringValue:[NSString stringWithFormat:NSLocalizedString( @"Loading %@...", @"Loading bundledPane" ), [self _labelForPaneBundle:bundle]]];
		[window setTitle:[NSString stringWithFormat:NSLocalizedString( @"PureFTPd Manager -  %@", @"PureFTPd Manager bundledPane (window title for a selected pane)" ), [self _labelForPaneBundle:bundle]]];
		[window setContentView:loadingView];
		[window display];
		if( ! ( pane = [loadedPanes objectForKey:identifier] ) ) {
			pane = [[[[bundle principalClass] alloc] initWithBundle:bundle] autorelease];
			if( pane ) [loadedPanes setObject:pane forKey:identifier];
		}
		if( [pane loadMainView] ) {
			[pane willSelect];
			prefView = [pane mainView];

			[self _resizeWindowForContentView:prefView];

			[[loadedPanes objectForKey:currentPaneIdentifier] willUnselect];
			[window setContentView:prefView];
			[[loadedPanes objectForKey:currentPaneIdentifier] didUnselect];
			[pane didSelect];
			[[NSNotificationCenter defaultCenter] postNotificationName:MVPreferencesWindowNotification object:self userInfo:[NSDictionary dictionaryWithObjectsAndKeys:window, @"window", nil]];
			[currentPaneIdentifier autorelease];
			currentPaneIdentifier = [identifier copy];

			[window setInitialFirstResponder:[pane initialKeyView]];
			[window makeFirstResponder:[pane initialKeyView]];
		} else NSRunCriticalAlertPanel( NSLocalizedString( @"Preferences Error", @"an error occured" ), [NSString stringWithFormat:NSLocalizedString( @"Could not load %@", @"Could not load bundledPane" ), [self _labelForPaneBundle:bundle]], nil, nil, nil );
	}
}

- (BOOL) savePanel{
    
    NSBeginAlertSheet(NSLocalizedString(@"PureFTPd Preferences have been modified",@"Preferences modified"), 
                      NSLocalizedString(@"Yes",@"Yes"), 
                      NSLocalizedString(@"No",@"No"), NULL,
                      window, self, @selector(sheetDidEnd:returnCode:contextInfo:), 
                      NULL, NULL, 
                      NSLocalizedString(@"Would you like to restart PureFTPd daemon now?",@"Restart PureFTPd Now"),
                      nil);
    NSModalSession session = [NSApp beginModalSessionForWindow:[NSApp mainWindow]];
    for (;;) {
        if ([NSApp runModalSession:session] != NSRunContinuesResponse)
            break;
    }
    [NSApp endModalSession:session];
    
    [pureFTPPreferences release];
    return YES;
}

- (void)sheetDidEnd: (NSWindow *)sheet
         returnCode: (int)returnCode
        contextInfo: (void *)contextInfo
{
    
    if (returnCode == NSAlertDefaultReturn)
    {   
        // restart main server
        [mainsrv restartServer];
    }
    

    [NSApp stopModal];

}

- (void)configureStartup{
    int atStartup = [[pureFTPPreferences objectForKey:PureFTPAtStartup] intValue];
    NSString *onOff = nil;
    switch (atStartup){
        case 0:
            onOff = @"PUREFTPD=-NO-";
            break;
        case 1 :
            onOff = @"PUREFTPD=-YES-";
            break;
    }
    
    NSString *hostConfig = [NSString stringWithContentsOfFile:@"/etc/hostconfig"];
    NSString *newConfig;
    NSRange pRange = [hostConfig rangeOfString:@"PUREFTPD"];
    
    if (pRange.length==0) // Can't find entry in /etc/hostconfig; we add it
        newConfig = [NSString stringWithString:[hostConfig stringByAppendingString:[NSString stringWithFormat:@"\n%@\n",onOff]]];
    else 
    {
        NSRange lineRange = [hostConfig lineRangeForRange:pRange];
        NSString *before = [NSString stringWithString:[hostConfig substringToIndex:lineRange.location]];
        NSString *after = [NSString stringWithString:[hostConfig substringFromIndex:NSMaxRange(lineRange)]];
        
        newConfig = [NSString stringWithFormat:@"%@%@\n%@", before, onOff, after];
    }
    
    [newConfig writeToFile:@"/etc/hostconfig" atomically:YES];
    
    switch ([[pureFTPPreferences objectForKey:PureFTPServerMode] intValue]){
        case 0:
            [self setupXinetd];
            break;
        case 1:
            [self setupStandAlone];
            break;
    }
}

- (void)setupXinetd
{
    NSString *disable =nil;
    int atStartup = [[pureFTPPreferences objectForKey:PureFTPAtStartup] intValue];
    switch (atStartup){
        case 0:
            disable = @"yes";
            break;
        case 1 :
            disable = @"no";
            break;
    }
    NSArray *args = [NSArray arrayWithArray:[mainsrv generateArguments]];
	SInt32 MacVersion;
	Gestalt(gestaltSystemVersion, &MacVersion);
	if (MacVersion < 0x1040){
		NSString *ftpFile = [NSString stringWithFormat:@"service ftp\n\
{\n\
\tdisable = %@\n\
\tsocket_type = stream\n\
\twait = no\n\
\tuser = root\n\
\tserver = /usr/local/sbin/pure-ftpd\n\
\tserver_args = %@\n\
\tgroups = yes\n\
\tflags = REUSE\n}", disable, [args componentsJoinedByString:@" "]];
    
    [ftpFile writeToFile:@"/etc/xinetd.d/ftp" atomically:NO];
	}else { // 10.4
		NSMutableDictionary *launchDaemon = [NSMutableDictionary dictionaryWithContentsOfFile:@"/System/Library/LaunchDaemons/ftp.plist"];
		[launchDaemon setObject:@"org.pureftpd.macosx" forKey:@"Label"];
		[launchDaemon setObject:PureFTPDCMD forKey:@"Program"];
		[launchDaemon setObject:args forKey:@"ProgramArguments"];
		[launchDaemon writeToFile:@"/System/Library/LaunchDaemons/ftp.plist" atomically:YES];
	}
    
}

- (void)setupStandAlone
{
    NSString *originalXinetd = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ftposx" ofType:nil]];
    [originalXinetd writeToFile:@"/etc/xinetd.d/ftp" atomically:NO];
}

- (BOOL) windowShouldClose:(id) sender {
    [[loadedPanes objectForKey:currentPaneIdentifier] willUnselect];
    [[loadedPanes objectForKey:currentPaneIdentifier] didUnselect];
    
    pureFTPPreferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    NSNumber *update = [NSNumber numberWithInt:[[pureFTPPreferences objectForKey:PureFTPPrefsUpdated] intValue]];

    if ([update intValue]) {
        NSNumber *update = [NSNumber numberWithInt:0];
        [pureFTPPreferences setObject:update forKey:PureFTPPrefsUpdated];
        [pureFTPPreferences writeToFile:PureFTPPreferenceFile atomically:YES];
        // Handle startup procedure
        [self configureStartup];
		
                
        if ([mainsrv isServerRunning]){
            return [self savePanel];
        }
    }
    
    if( currentPaneIdentifier && [[loadedPanes objectForKey:currentPaneIdentifier] shouldUnselect] != NSUnselectNow ) {
        //NSLog( @"can't unselect current" );
        closeWhenPaneIsReady = YES;
        return NO;
    }   
    [pureFTPPreferences release];
    return YES;
}

- (void) windowWillClose:(NSNotification *) notification {
    //[[loadedPanes objectForKey:currentPaneIdentifier] willUnselect];
	//[[loadedPanes objectForKey:currentPaneIdentifier] didUnselect];
	[currentPaneIdentifier autorelease];
	currentPaneIdentifier = nil;
	//[loadedPanes removeAllObjects];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (NSToolbarItem *) toolbar:(NSToolbar *) toolbar itemForItemIdentifier:(NSString *) itemIdentifier willBeInsertedIntoToolbar:(BOOL) flag {
	NSToolbarItem *toolbarItem = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];
	if( [itemIdentifier isEqualToString:MVToolbarShowAllItemIdentifier] ) {
		[toolbarItem setLabel:NSLocalizedString( @"Show All", @"Show all - button title" )];
		[toolbarItem setImage:[NSImage imageNamed:@"preferences"]];
		[toolbarItem setTarget:self];
		[toolbarItem setAction:@selector( showAll: )];
	} else {
		NSBundle *bundle = [NSBundle bundleWithIdentifier:itemIdentifier];
		if( bundle ) {
			[toolbarItem setLabel:[self _labelForPaneBundle:bundle]];
			[toolbarItem setPaletteLabel:[self _paletteLabelForPaneBundle:bundle]];
			[toolbarItem setImage:[self _imageForPaneBundle:bundle]];
			[toolbarItem setTarget:self];
			[toolbarItem setAction:@selector( _selectPreferencePane: )];
		} else toolbarItem = nil;
	}
	return toolbarItem;
}

- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *) toolbar {
	NSMutableArray *fixed = [NSMutableArray arrayWithObjects:MVToolbarShowAllItemIdentifier, NSToolbarSeparatorItemIdentifier, nil];
	NSArray *defaults = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"MVPreferencePaneDefaults" ofType:@"plist"]];
	[fixed addObjectsFromArray:defaults];
	return fixed;
}

- (NSArray *) toolbarAllowedItemIdentifiers:(NSToolbar *) toolbar {
	NSMutableArray *items = [NSMutableArray array];
	NSEnumerator *enumerator = [panes objectEnumerator];
	id item = nil;
	while( ( item = [enumerator nextObject] ) )
		[items addObject:[item bundleIdentifier]];
	[items addObject:NSToolbarSeparatorItemIdentifier];
	return items;
}
@end

@implementation MVPreferencesController (MVPreferencesControllerPrivate)
- (IBAction) _selectPreferencePane:(id) sender {
	[self selectPreferencePaneByIdentifier:[sender itemIdentifier]];
}

- (void) _doUnselect:(NSNotification *) notification {
	if( closeWhenPaneIsReady ) [window close];
    if ( [pendingPane isEqualToString:@""] ) {
        [self showAll:self];
        [pendingPane release];
        pendingPane = nil;
	} else {
        [self selectPreferencePaneByIdentifier:pendingPane];
    }
}

- (void) _resizeWindowForContentView:(NSView *) view {
	NSRect windowFrame, newWindowFrame;
	unsigned int newWindowHeight, newWindowWidth;

	windowFrame = [NSWindow contentRectForFrameRect:[window frame] styleMask:[window styleMask]];
	newWindowHeight = NSHeight( [view frame] );
        newWindowWidth = NSWidth ( [view frame] );
	if( [[window toolbar] isVisible] )
		newWindowHeight += NSHeight( [[[window toolbar] _toolbarView] frame] );
	newWindowFrame = [NSWindow frameRectForContentRect:NSMakeRect( NSMinX( windowFrame ), NSMaxY( windowFrame ) - newWindowHeight, newWindowWidth, newWindowHeight ) styleMask:[window styleMask]];

	[window setFrame:newWindowFrame display:YES animate:[window isVisible]];
}

- (NSImage *) _imageForPaneBundle:(NSBundle *) bundle {
	NSImage *image = nil;
	NSMutableDictionary *cache = [paneInfo objectForKey:[bundle bundleIdentifier]];
	image = [[[cache objectForKey:@"MVPreferencePaneImage"] retain] autorelease];
	if( ! image ) {
		NSDictionary *info = [bundle infoDictionary];
		image = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:[info objectForKey:@"NSPrefPaneIconFile"]]] autorelease];
		if( ! image ) image = [[[NSImage alloc] initWithContentsOfFile:[bundle pathForImageResource:[info objectForKey:@"CFBundleIconFile"]]] autorelease];
		if( ! cache ) [paneInfo setObject:[NSMutableDictionary dictionary] forKey:[bundle bundleIdentifier]];
		cache = [paneInfo objectForKey:[bundle bundleIdentifier]];
		if( image ) [cache setObject:image forKey:@"MVPreferencePaneImage"];
	}
	return image;
}

- (NSString *) _paletteLabelForPaneBundle:(NSBundle *) bundle {
	NSString *label = nil;
	NSMutableDictionary *cache = [paneInfo objectForKey:[bundle bundleIdentifier]];
	label = [[[cache objectForKey:@"MVPreferencePanePaletteLabel"] retain] autorelease];
	if( ! label ) {
		NSDictionary *info = [bundle infoDictionary];
		label = NSLocalizedStringFromTableInBundle( @"NSPrefPaneIconLabel", @"InfoPlist", bundle, nil );
		if( [label isEqualToString:@"NSPrefPaneIconLabel"] ) label = [info objectForKey:@"NSPrefPaneIconLabel"];
		if( ! label ) label = NSLocalizedStringFromTableInBundle( @"CFBundleName", @"InfoPlist", bundle, nil );
		if( [label isEqualToString:@"CFBundleName"] ) label = [info objectForKey:@"CFBundleName"];
		if( ! label ) label = [bundle bundleIdentifier];
		if( ! cache ) [paneInfo setObject:[NSMutableDictionary dictionary] forKey:[bundle bundleIdentifier]];
		cache = [paneInfo objectForKey:[bundle bundleIdentifier]];
		if( label ) [cache setObject:label forKey:@"MVPreferencePanePaletteLabel"];
	}
	return label;
}

- (NSString *) _labelForPaneBundle:(NSBundle *) bundle {
	NSString *label = nil;
	NSMutableDictionary *cache = [paneInfo objectForKey:[bundle bundleIdentifier]];
	label = [[[cache objectForKey:@"MVPreferencePaneLabel"] retain] autorelease];
	if( ! label ) {
		NSDictionary *info = [bundle infoDictionary];
		label = NSLocalizedStringFromTableInBundle( @"CFBundleName", @"InfoPlist", bundle, nil );
		if( [label isEqualToString:@"CFBundleName"] ) label = [info objectForKey:@"CFBundleName"];
		if( ! label ) label = [bundle bundleIdentifier];
		if( ! cache ) [paneInfo setObject:[NSMutableDictionary dictionary] forKey:[bundle bundleIdentifier]];
		cache = [paneInfo objectForKey:[bundle bundleIdentifier]];
		if( label ) [cache setObject:label forKey:@"MVPreferencePaneLabel"];
	}
	return label;
}
@end    

