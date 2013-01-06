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


#import "defines.h"
#import "UserController.h"
#import "PureController.h"
#include <signal.h>
#include <sys/types.h>
#include <pwd.h>
#include <grp.h>

#import "FSNodeInfo.h"
#import "FSBrowserCell.h"

#import "NSFileManager+ASExtensions.h"

#define MAX_VISIBLE_COLUMNS 3

@interface UserController (PrivateUtilities)
- (NSString*)fsPathToColumn:(int)column;
@end

@implementation UserController (PrivateUtilities)

- (NSString*)fsPathToColumn:(int)column {
    NSString *path = nil;
    if(column==0) path = [NSString stringWithFormat: @"/"];
    else path = [fileBrowser pathToColumn: column];
    return path;
}

@end


UserController* theUserController = nil;

@implementation UserController
#pragma mark Initialization methods
+(id) getInstance
{
    // TODO: Mutex Begin
    if (theUserController == nil) {
        theUserController = [[UserController alloc] init];
    }
    // TODO: Mutex End
    return theUserController;
}


-(id) init 
{
    self = [super init];
    if (self)
    {
        theUserController = self;
        authMethods = [[NSMutableArray alloc] initWithArray:[[NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile] objectForKey:PureFTPAuthentificationMethods]];
        userVFolderList = [[NSMutableArray alloc] init];
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(generateAuthentificationPopUp)
                                                     name:@"reloadAuthMethods" object:@"org.pureftpd.osx"];
        sidebar = nil;
       
		
    }
    return self;
}




-(void) dealloc
{
    [authMethods release];
    [authMenu release];
    [myUsersDictionary release];
    if (userVFolderList)
        [userVFolderList release];
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self];
    if (MacVersion >= 0x1030)
    {
        [splitview release];
    } else {
        [fileBrowserView release];
    }
    [super dealloc];
}



-(void) awakeFromNib
{
    
    NSRect navViewBounds = [navView bounds];
    Gestalt(gestaltSystemVersion, &MacVersion);
    
    if (MacVersion >= 0x1030)
    {
        splitview = [[JMNavSplitView alloc] initWithFrame:navViewBounds];
        fileBrowser = [splitview fileBrowser];
        sidebar = [splitview sidebar];
        
        [navView addSubview:splitview];
        
    } else {
        fileBrowserView = [[NSBrowserView alloc] initWithFrame:navViewBounds];
        [fileBrowserView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
        fileBrowser = [fileBrowserView fileBrowser];
        [navView addSubview:fileBrowserView];
    }
    
        
    
    // Prime the browser with an initial load of data.
    [self reloadBrowserData: nil];
  
    [self setUserAndGroupPopup];
    currentUserManager = PureDB;
    
    [self generateAuthentificationPopUp];
    pureController = [PureController getInstance];
    pureUM = [PureDBUserManager getInstance];
    mySQLUM = [MySQLUserManager getInstance];
    
	[timeBeginControl setDelegate:self];
	[timeBeginControl setAlignStepper:YES];
	[timeBeginControl updateCells];
	
	[timeEndControl setDelegate:self];
	[timeEndControl setAlignStepper:YES];
	[timeEndControl updateCells];
	
    //[self synchronizeUserDB];
    [self changeUserDB:@"PureDB"];
    [self disableUserFields];
    
    [fileBrowser setEnabled:NO];

}

- (IBAction)reloadBrowserData:(id)sender {
    [fileBrowser loadColumnZero];
}

- (void)setBrowserPath:(NSString *)aPath
{
    if ([fileBrowser isEnabled])
        [fileBrowser setPath:aPath];
}

// ==========================================================
#pragma mark Browser Delegate Methods.
// ==========================================================

// Use lazy initialization, since we don't want to touch the file system too much.
- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column {
    NSString   *fsNodePath = nil;
    FSNodeInfo *fsNodeInfo = nil;
    
    // Get the absolute path represented by the browser selection, and create a fsnode for the path.
    // Since column represents the column being (lazily) loaded fsNodePath is the path for the last selected cell.
    fsNodePath = [self fsPathToColumn: column];
    fsNodeInfo = [FSNodeInfo nodeWithParent: nil atRelativePath: fsNodePath];
    
    return [[fsNodeInfo visibleSubNodes] count];
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column {
    NSString   *containingDirPath = nil;
    FSNodeInfo *containingDirNode = nil;
    FSNodeInfo *displayedCellNode = nil;
    NSArray    *directoryContents = nil;
    
    // Get the absolute path represented by the browser selection, and create a fsnode for the path.
    // Since (row,column) represents the cell being displayed, containingDirPath is the path to it's containing directory.
    containingDirPath = [self fsPathToColumn: column];
    containingDirNode = [FSNodeInfo nodeWithParent: nil atRelativePath: containingDirPath];
    
    // Ask the parent for a list of visible nodes so we can get at a FSNodeInfo for the cell being displayed.
    // Then give the FSNodeInfo to the cell so it can determine how to display itself.
    directoryContents = [containingDirNode visibleSubNodes];
    displayedCellNode = [directoryContents objectAtIndex: row];
    
    [cell setAttributedStringValueFromFSNodeInfo: displayedCellNode];
}

// ==========================================================
#pragma mark Browser Target / Action Methods.
// ==========================================================

- (IBAction)browserSingleClick:(id)browser {
     
}

- (IBAction)browserDoubleClick:(id)browser {
    if(currentUser == nil)
        return;
    // Open the file and display it information by calling the single click routine.
    NSString *nodePath = [browser path];
    //[self browserSingleClick: browser];
    //[[NSWorkspace sharedWorkspace] openFile: nodePath];
    
    
    NSString *home = nil;
    if ([[[currentUser home] lastPathComponent] isEqualToString:@"."])
        home = [[currentUser home] stringByDeletingLastPathComponent];
    else
        home = [currentUser home];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    struct passwd *userInfo;
    struct group *groupInfo;
    
    if (![fm fileExistsAtPath:home] ){
        userInfo = getpwuid([[currentUser uid] intValue]);
        groupInfo = getgrgid([[currentUser gid] intValue]);
		if (userInfo == NULL)
			userInfo = getpwnam("nobody");
		if (groupInfo == NULL)
			groupInfo = getgrnam("nobody");
		
        NSString *username = [NSString stringWithCString:userInfo->pw_name];
        NSString *group = [NSString stringWithCString:groupInfo->gr_name];
        
        NSNumber *permissions = [NSNumber numberWithInt:0755];
        NSArray *objects = [NSArray arrayWithObjects:permissions, username,  group, nil];
        NSArray *keys = [NSArray arrayWithObjects:NSFilePosixPermissions, NSFileOwnerAccountName, NSFileGroupOwnerAccountName, nil];
        NSDictionary *posixAttributes = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
        NSDictionary *rootPosixAttrs = [NSDictionary dictionaryWithObject:permissions forKey:NSFilePosixPermissions];
        if (![fm createDirectoryAtPath:[home stringByDeletingLastPathComponent] attributes:rootPosixAttrs recursive:YES])
            return;
        else {
            [fm createDirectoryAtPath:home attributes:posixAttributes];
        }
    }

    
    NSString *linkDest = [NSString stringWithFormat:@"%@/%@", home, [nodePath lastPathComponent]];
    NSFileWrapper *fw = [[[NSFileWrapper alloc] initSymbolicLinkWithDestination:nodePath] autorelease];
    [fw writeToFile:linkDest atomically:YES updateFilenames:NO];
    
	int checkVFolder = 0;
    checkVFolder = [[[NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile] objectForKey:PureFTPCheckVFolderPerm] intValue];
    if (checkVFolder == 1)
    {
        [self adjustAccessToFolder:nil];
    }

    [self refreshVFolderList];
}

- (IBAction)adjustAccessToFolder:(id)sender
{
    
    if(currentUser == nil)
        return;
    
    struct passwd *userInfo;
    struct group *groupInfo;
    
    NSString *path = nil;
    path = [fileBrowser path];
    
    if ((path == nil) || ([path isEqualToString:@"/"]))
        return;
    
    userInfo = getpwuid([[currentUser uid] intValue]);
    groupInfo = getgrgid([[currentUser gid] intValue]);
	if (userInfo == NULL)
			userInfo = getpwnam("nobody");
	if (groupInfo == NULL)
			groupInfo = getgrnam("nobody");
		
    NSString *username = [NSString stringWithCString:userInfo->pw_name];
    NSString *group = [NSString stringWithCString:groupInfo->gr_name];
    
    BOOL modified = NO;
    int showVFolderLog = 0;
    
    showVFolderLog = [[[NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile] objectForKey:PureFTPShowVFolderConsole] intValue];
    
    NSArray *info = [[NSFileManager defaultManager] adjustAccessPermissionsTo:path forUser:username  ofGroup:group modified:&modified];
    if (showVFolderLog==1)
    {
        if (modified){
            [vfolderResultTextView setString:@""];
            NSEnumerator *rator = [info objectEnumerator];
            id string = nil;
            while (string = [rator nextObject]){
                if (![string isEqualToString:@""])
                    [self  appendString:string toText:vfolderResultTextView];
            }
        } else {
            [vfolderResultTextView setString:NSLocalizedString(@"Permissions did not need to be modified", @"Permissions did not need to be modified")];
        }
        
        [vfolderResultPanel makeKeyAndOrderFront:nil];
    }
}

- (IBAction)setAccessToFolder:(id)sender
{
    if(currentUser == nil)
        return;
    
    struct passwd *userInfo;
    struct group *groupInfo;
    
    NSString *fullPath  = nil;
    if([vfolderTable selectedRow] != -1){
        NSString *lpc =  [userVFolderList objectAtIndex:[vfolderTable selectedRow]];
         fullPath =  [[NSString stringWithFormat:@"%@/%@", [currentUser home], lpc] stringByResolvingSymlinksInPath];
    } else {
        return;
    }
    
    if ((fullPath == nil) || ([fullPath isEqualToString:@"/"]))
        return;
    
    userInfo = getpwuid([[currentUser uid] intValue]);
    groupInfo = getgrgid([[currentUser gid] intValue]);
    if (userInfo == NULL)
        userInfo = getpwnam("nobody");
    if (groupInfo == NULL)
        groupInfo = getgrnam("nobody");
    
    NSString *username = [NSString stringWithCString:userInfo->pw_name];
    NSString *group = [NSString stringWithCString:groupInfo->gr_name];
    NSFileManager *fm = [NSFileManager defaultManager];
	
	BOOL notRecursive = YES;
	NSString *newPerm = @"";
	
	int selectedOption = [accessPopUp indexOfSelectedItem];
	
	switch (selectedOption){
		case 0: // read only
			newPerm = NSLocalizedString(@"read only", @"read only");
			break;
		case 1: // write only
			newPerm = NSLocalizedString(@"write only (Dropbox)", @"write only (Dropbox)");
			break;
		case 2: // read & write
			newPerm = NSLocalizedString(@"read/write", @"read/write");
			break;
		case 3: // none
			newPerm = NSLocalizedString(@"no access", @"no access");
			break;
		default: //do nothing
			break;
	}
	
	if (selectedOption !=1 && selectedOption !=3){
		NSString *local = NSLocalizedString(@"You are about to modify %@ permissions to %@. Do you want to modify its contents (files and folders) permissions recursively ?\nThis may take a long time.", 
										@"You are about to modify %@ permissions to %@. Do you want to modify its contents (files and folders) permissions recursively ?\nThis may take a long time.");
		notRecursive = NSRunAlertPanel(NSLocalizedString(@"Filesystem permissions modification", @"Filesystem permissions modification"),
									[NSString stringWithFormat:local, fullPath, newPerm],
									NSLocalizedString(@"No", @"No"),
									NSLocalizedString(@"Yes", @"Yes"),
									nil);
	}
	
	
	
	if (!notRecursive){ // because YES is not the default return of our alert
		///
		NSDirectoryEnumerator *dirEnum = [fm enumeratorAtPath:fullPath];
		NSString *file=nil;
		while (file = [dirEnum nextObject]) {
			NSString *path = [fullPath stringByAppendingPathComponent:file];
			if ([[NSWorkspace sharedWorkspace] isFilePackageAtPath:path])
			{
				[dirEnum skipDescendents];
				continue;
			} 
			[fm clearPermissionAtPath:path forUser:username ofGroup:group];
			switch (selectedOption){
				case 0: // read only
				[fm setReadPermissionAtPath:path forUser:username ofGroup:group];
				[fm setExecutePermissionAtPath:path forUser:username ofGroup:group];
				break;
			case 1: // write only
				[fm setWritePermissionAtPath:path forUser:username ofGroup:group];
				[fm setExecutePermissionAtPath:path forUser:username ofGroup:group];
				break;
			case 2: // read & write
				[fm setReadPermissionAtPath:path forUser:username ofGroup:group];
				[fm setWritePermissionAtPath:path forUser:username ofGroup:group];
				[fm setExecutePermissionAtPath:path forUser:username ofGroup:group];
				break;
			case 3: // none
				break;
			default: //do nothing
				break;
			
			}
		}
	}
	
    [fm clearPermissionAtPath:fullPath forUser:username ofGroup:group];
    switch (selectedOption){
        case 0: // read only
            [fm setReadPermissionAtPath:fullPath forUser:username ofGroup:group];
            [fm setExecutePermissionAtPath:fullPath forUser:username ofGroup:group];
            break;
        case 1: // write only
            [fm setWritePermissionAtPath:fullPath forUser:username ofGroup:group];
            [fm setExecutePermissionAtPath:fullPath forUser:username ofGroup:group];
            break;
        case 2: // read & write
            [fm setReadPermissionAtPath:fullPath forUser:username ofGroup:group];
            [fm setWritePermissionAtPath:fullPath forUser:username ofGroup:group];
            [fm setExecutePermissionAtPath:fullPath forUser:username ofGroup:group];
            break;
        case 3: // none
            break;
        default: //do nothing
            break;
    }
    
}

- (void)getAccessToFolder:(NSString *)path
{
    struct passwd *userInfo;
    struct group *groupInfo;
    
    userInfo = getpwuid([[currentUser uid] intValue]);
    groupInfo = getgrgid([[currentUser gid] intValue]);
    if (userInfo == NULL)
        userInfo = getpwnam("nobody");
    if (groupInfo == NULL)
        groupInfo = getgrnam("nobody");
    
    NSString *username = [NSString stringWithCString:userInfo->pw_name];
    NSString *group = [NSString stringWithCString:groupInfo->gr_name];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL canRead = NO, canWrite = NO, canExecute = NO;
    canRead = [fm user:username ofGroup:group canReadDirectory:path];
    canWrite= [fm user:username ofGroup:group canWriteDirectory:path];
    canExecute = [fm user:username ofGroup:group canTraverseDirectory:path];
    
    if (canRead && !canWrite && canExecute){
        // read only
        [accessPopUp selectItemAtIndex:0];
    } else if (!canRead && canWrite && canExecute) {
        // DropBox
        [accessPopUp selectItemAtIndex:1];
    } else if (canRead && canWrite) {
        // Read & write
        [accessPopUp selectItemAtIndex:2];
    } else {
        // None
        [accessPopUp selectItemAtIndex:3];
    }
}

#define END_RANGE NSMakeRange([[tv string]length],0)
- (void)appendString:(NSString *)string toText:(NSTextView *)tv
{
    [tv replaceCharactersInRange:END_RANGE withString:string];
    [tv replaceCharactersInRange:END_RANGE withString:@"\n"];
    
    if ([[tv window] isVisible]) {
        [tv scrollRangeToVisible:END_RANGE];
    }
}


#pragma mark Virtual Folders detection / deletion
- (void)refreshVFolderList
{
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];   
    [userVFolderList removeAllObjects];
    if (currentUser == nil){
        [vfolderTable reloadData];
        return;
    }
    
    NSString *userHome = [NSString stringWithString:[currentUser home]];
    NSArray *pathComponents = [userHome componentsSeparatedByString:@"/"];
    if ([[pathComponents objectAtIndex:[pathComponents count]-2] isEqualToString:@"."])
    {
        userHome = [userHome stringByDeletingLastPathComponent];
    }
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath: userHome]){
        NSArray *dirContent = [fm directoryContentsAtPath:userHome];
        if(nil == dirContent)
            return;
        
        NSArray * contents = [NSArray arrayWithArray:dirContent];
        NSEnumerator *contentsEnum = [contents objectEnumerator];
        NSString *dirName;
        BOOL isDir;
        
        while(dirName = [contentsEnum nextObject]){
            NSString *fullPath = [userHome stringByAppendingPathComponent:dirName];
            if ([fm fileExistsAtPath:fullPath isDirectory:&isDir] && isDir)
            {
                
                /*NSFileWrapper *fw = [[NSFileWrapper alloc] initWithPath:fullPath];
                if (![fw isSymbolicLink]){
                    [fw release];
                    fw = nil;
                } else {
                    [userVFolderList addObject:dirName];
                }
                
                if(fw != nil){
                    [fw release];
                    fw = nil;
                }*/
                
                if ([[[fm fileAttributesAtPath:fullPath traverseLink:NO] fileType] isEqualToString:NSFileTypeSymbolicLink])
                    [userVFolderList addObject:dirName];
            }
        } 
    }
    
    [vfolderTable reloadData];
   // [pool release];
    
}

- (IBAction)removeVFolder:(id)sender
{
    NSString *home = nil;
    if ([[[currentUser home] lastPathComponent] isEqualToString:@"."])
        home = [[currentUser home] stringByDeletingLastPathComponent];
    else
        home = [currentUser home];
    
    NSString *linkName = [userVFolderList objectAtIndex:[vfolderTable selectedRow]];
    NSString *linkPath = [home stringByAppendingPathComponent:linkName];
	NSFileWrapper *fw = [[NSFileWrapper alloc] initWithPath:linkPath];
	
	if ([fw isSymbolicLink])
		[[NSFileManager defaultManager] removeFileAtPath:linkPath handler:nil];
    
	[fw release];
    //[NSThread detachNewThreadSelector:@selector(refreshVFolderList) toTarget:self withObject:nil];
    [self refreshVFolderList];
}

#pragma mark Utility methods
- (NSTableView *)userTable
{
    return userTable;
}

-(void) setUserAndGroupPopup
{
    NSString *username;
    NSString *groupname;
    struct passwd *userInfo;
    struct group *groupInfo;
    
    [userPopUp removeAllItems];
    [groupPopUp removeAllItems];
    
    while((userInfo=getpwent()) != NULL)
    {
        username = [NSString stringWithFormat:@"%s", userInfo->pw_name];
        [userPopUp addItemWithTitle:username];
        [[userPopUp lastItem] setTag: (int)userInfo->pw_uid];
    }
    
    while((groupInfo=getgrent()) != NULL)
    {
        groupname = [NSString stringWithFormat:@"%s", groupInfo->gr_name];
        [groupPopUp addItemWithTitle:groupname];
        [[groupPopUp lastItem] setTag: groupInfo->gr_gid];
    }
}


- (void)generateAuthentificationPopUp{
    if (authMenu)
        [authMenu release];
    if(authMethods)
        [authMethods release];
    
    authMethods = [[NSMutableArray alloc] initWithArray:[[NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile] objectForKey:PureFTPAuthentificationMethods]]; 
    
    authMenu = [[NSMenu alloc] init];
    NSMenuItem *anItem; 
    
    NSEnumerator *authEnum = [authMethods objectEnumerator];
    id entry;
    
    while (entry = [authEnum nextObject]) {
        if  ((![[entry objectForKey:@"auth.type"] isEqualToString:@"PAM"]) && (![[entry objectForKey:@"auth.type"] isEqualToString:@"Unix"])) {
        anItem = [[NSMenuItem alloc] initWithTitle:[entry objectForKey:@"auth.type"]
                                            action:@selector(changeUserDB:)
                                     keyEquivalent:@" "];
        [anItem setTag:0];
        [anItem setTarget:self];
        [authMenu addItem:anItem];
        [anItem release];
        }
    }
    
    [userDBPopUp setMenu:authMenu];

}

#pragma mark UserInterface User methods

-(void)changeUserDB:(id)sender
{
    NSString *database;
    if ([sender isKindOfClass:[NSMenuItem class]]){
        database = [sender title];
    } else {
        database = sender;
    }
    
    if ([database isEqualToString:@"PureDB"]){
        currentUserManager = PureDB;
    } else if ([database isEqualToString:@"MySQL"]){
        
        if (![mySQLUM cacheUsers]){
            currentUserManager = PureDB;
            [userDBPopUp selectItemAtIndex:0];
            NSBeginCriticalAlertSheet(NSLocalizedString(@"Connection error to MySQL", @"Connection error to MySQL"),
                                     nil,nil,nil,[NSApp mainWindow],nil,nil,nil,nil,
                                      NSLocalizedString(@"Please check that your MySQL server is running", @"Please check that your MySQL server is running"));
            
        } else {
            currentUserManager = MySQL;
        }
    }
    
    [self synchronizeUserDB];
}

- (IBAction)chrootAccess:(id)sender
{
    if ([chrootSwitch state] == 1)
    {
        [currentUser setHome:[[homeDirField stringValue] stringByAppendingString:@"/./"]];
    }
    else
        [currentUser setHome:[[homeDirField stringValue] stringByAppendingString:@"/"]];
    
    [currentUser setHasBeenEdited:YES];
}

- (IBAction)chooseDir:(id)sender
{ 
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	if ([oPanel respondsToSelector:@selector(setCanCreateDirectories:)])
		[oPanel setCanCreateDirectories:YES];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:NO];
    [oPanel setResolvesAliases:NO];
    
    [oPanel beginSheetForDirectory:NSHomeDirectoryForUser([pureController activeUser]) file:nil types:nil 
                    modalForWindow:[NSApp mainWindow]
                     modalDelegate: self
                    didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo: (void *)[sender tag]];
    
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
       [NSApp stopModal];
    if (returnCode == NSOKButton){
        [homeDirField setStringValue: [[sheet filenames] objectAtIndex:0]];
        if ([chrootSwitch state] == 1)
        {
            [currentUser setHome:[[homeDirField stringValue] stringByAppendingString:@"/./"]];
        }
        else
            [currentUser setHome:[[homeDirField stringValue] stringByAppendingString:@"/"]];
        
        [currentUser setHasBeenEdited:YES];
    }
    
}

- (IBAction)resetPassword:(id)sender
{
    [passwordField setStringValue:@""];
    [passwordField setEnabled:YES];
}

- (IBAction)toggleAccountStatus:(id)sender
{
	[currentUser setIsActivated:[sender state]];
	[currentUser setHasBeenEdited:YES];
}

- (IBAction)setGroupID:(id)sender
{
    [currentUser setGid:[NSString stringWithFormat:@"%d", [[groupPopUp selectedItem] tag]]];
    
    [currentUser setHasBeenEdited:YES];
}

- (IBAction)setTimeValue:(id)sender
{
	WBTimeControl *IBtimeControl=nil;
    
    if ([sender tag] == 0)
        IBtimeControl = timeBeginControl;
    else if ([sender tag] == 1)
        IBtimeControl = timeEndControl;
		
	[IBtimeControl handleStepperClick:sender];
	
	[currentUser setTimeBegin: [NSString stringWithFormat:@"%02d%02d", 
        [timeBeginControl hour],
        [timeBeginControl minute]]];
    [currentUser setTimeEnd: [NSString stringWithFormat:@"%02d%02d", 
        [timeEndControl hour],
		[timeEndControl minute]]];
    
    [currentUser setHasBeenEdited:YES];
}

/*- (IBAction)setTimeValue:(id)sender
{
    WBTimeControl *IBtimeControl=nil;
    
    if ([sender tag] == 0)
        IBtimeControl = timeBeginControl;
    else if ([sender tag] == 1)
        IBtimeControl = timeEndControl;
    
    switch([IBtimeControl selected])
    {
        case 0:
            [IBtimeControl setHour:[sender intValue]];
            break;
        case 1:
            [IBtimeControl setMinute:[sender intValue]];
            break;
        case 2:
            [IBtimeControl setSecond:[sender intValue]];
            break;
    }
    // set time to Virtual user
    [currentUser setTimeBegin: [NSString stringWithFormat:@"%02d%02d", 
        [[timeBeginControl date] hourOfDay],
        [[timeBeginControl date] minuteOfHour]]];
    [currentUser setTimeEnd: [NSString stringWithFormat:@"%02d%02d", 
        [[timeEndControl date] hourOfDay],
        [[timeEndControl date] minuteOfHour]]];
    
    [currentUser setHasBeenEdited:YES];
}
*/
- (IBAction)setUserID:(id)sender
{
    [currentUser setUid:[NSString stringWithFormat:@"%d", [[userPopUp selectedItem] tag]]];
    [currentUser setHasBeenEdited:YES];
    
}

- (IBAction)toggleTimeRestrictions:(id)sender
{
    switch([sender state])
    {
        case NSOnState:
			[timeBeginControl setEnabled:YES];
            [timeEndControl setEnabled:YES];
			[timeAccessField setTextColor:[NSColor blackColor]];
           // [[timeBeginControl stepper] setEnabled:YES];
           // [[timeEndControl stepper] setEnabled:YES];
            [currentUser setTimeBegin: [NSString stringWithFormat:@"%02d%02d", 
                [timeBeginControl hour],
                [timeBeginControl minute]]];
            [currentUser setTimeEnd: [NSString stringWithFormat:@"%02d%02d", 
                [timeEndControl hour],
                [timeEndControl minute]]];
            //[timeAccessSwitch setTitle:NSLocalizedString(@"Enabled",@"Enabled")];
			
            break;
        case NSOffState:
			[timeBeginControl setEnabled:NO];
            [timeEndControl setEnabled:NO];
			[timeAccessField setTextColor:[NSColor disabledControlTextColor]];
           // [[timeBeginControl stepper] setEnabled:NO];
           // [[timeEndControl stepper] setEnabled:NO];
            [currentUser setTimeBegin:@""];
            [currentUser setTimeEnd:@""];
            //[timeAccessSwitch setTitle:NSLocalizedString(@"Disabled",@"Disabled")];
            break;
    }
    
    [currentUser setHasBeenEdited:YES];
    
}

- (IBAction)removeBanner:(id)sender
{
    [currentUser setBanner:@""];
    [bannerTextView setString:@""];
    [removeBannerBtn setEnabled:NO];
}

- (IBAction)userIPFilter:(id)sender
{
    VirtualUser *user = currentUser;
    
    if(!currentUser)
    {
        return;
    }
        
    int row = -1;
    if ([sender tag] == 10 && (![[allowClientField stringValue] isEqualToString:@""]))
    {
        [[user allow_client_ip] addObject:[allowClientField stringValue]];
        [allowClientField setStringValue:@""];
        [allowClientTable reloadData];
        
    }
    else if (([sender tag] == 11) && ((row=[allowClientTable selectedRow]) != -1))
    {
        [[user allow_client_ip] removeObjectAtIndex:row];
        [allowClientTable reloadData];
    }
    else if (([sender tag] == 20) && (![[denyClientField stringValue] isEqualToString:@""]))
    {
        [[user deny_client_ip] addObject:[denyClientField stringValue]];
        [denyClientField setStringValue:@""];
        [denyClientTable reloadData];
    }
    else if (([sender tag] == 21) && ((row=[denyClientTable selectedRow]) != -1))
    {
        [[user deny_client_ip] removeObjectAtIndex:row];
        [denyClientTable reloadData];
    }
    
    [user setHasBeenEdited:YES];
}



#pragma mark Fields enabling/disabling

-(void)disableUserFields
{
    [self clearFields];
    [fullNameField setEnabled:NO];
    [loginField setEnabled:NO];
    [passwordField setEnabled:NO];
	[activationSwitch setEnabled:NO];
	[activationSwitch setState:1];
    [resetPwdButton setEnabled:NO];
    [homeDirField setEnabled:NO];
    [chooseUserDirButton setEnabled:NO];
    [chrootSwitch setEnabled:NO];
    [timeAccessSwitch setEnabled:NO];
	[timeAccessField setTextColor:[NSColor disabledControlTextColor]];
	[timeBeginControl setEnabled:NO];
	[timeEndControl setEnabled:NO];
    [userPopUp setEnabled:NO];
    [groupPopUp setEnabled:NO];
    [maxSessionsField setEnabled:NO];
    [upRatioField setEnabled:NO];
    [downRatioField setEnabled:NO];
    [upBwField setEnabled:NO];
    [downBwField setEnabled:NO];
    [fileQuotaField setEnabled:NO];
    [sizeQuotaField setEnabled:NO];
    [denyClientField setEnabled:NO];
    [allowClientField setEnabled:NO];
    [bannerTextView setString:@""];
    [removeBannerBtn setEnabled:NO];
    [bannerTextView setEditable:NO];
    [allowClientRemoveButton setEnabled:NO];
    [denyClientRemoveButton setEnabled:NO];
    [fileBrowser setEnabled:NO];
    if (sidebar !=nil)
    {
        [sidebar setEnabled:NO];
    }
}

-(void)enableUserFields
{

    if (![currentUser isNewUser])
    {
        [loginField setEnabled:NO];
        [passwordField setEnabled:NO];
    }
    else
    {
        [loginField setEnabled:YES];
        [passwordField setEnabled:YES];
    }
    
    if (currentUserManager != MySQL){
        [fullNameField setEnabled:YES];
        [timeAccessSwitch setEnabled:YES];
        [maxSessionsField setEnabled:YES];
        [denyClientField setEnabled:YES];
        [allowClientField setEnabled:YES];
		[activationSwitch setEnabled:YES];
    } else {
        [fullNameField setEnabled:NO];
        [timeAccessSwitch setEnabled:NO];
        [maxSessionsField setEnabled:NO];
        [denyClientField setEnabled:NO];
        [allowClientField setEnabled:NO];
		[activationSwitch setEnabled:NO];
		[activationSwitch setState:1];
    }
    
    [resetPwdButton setEnabled:YES];
    [homeDirField setEnabled:YES];
    [chooseUserDirButton setEnabled:YES];
    [chrootSwitch setEnabled:YES];
    [userPopUp setEnabled:YES];
    [groupPopUp setEnabled:YES];
    [upRatioField setEnabled:YES];
    [downRatioField setEnabled:YES];
    [upBwField setEnabled:YES];
    [downBwField setEnabled:YES];
    [fileQuotaField setEnabled:YES];
    [sizeQuotaField setEnabled:YES];
    
    [bannerTextView setEditable:YES];
    [removeBannerBtn setEnabled:YES];
    [fileBrowser setEnabled:YES];
    if (sidebar !=nil)
    {
        [sidebar setEnabled:YES];
    }
}

-(void) clearFields
{
    [fullNameField setStringValue:@""];
    [loginField setStringValue:@""];
    [passwordField setStringValue:@""];
    [homeDirField setStringValue:@""];
    [chrootSwitch setState:NO];
    [maxSessionsField setStringValue:@""];
    [upRatioField setStringValue:@""];
    [downRatioField setStringValue:@""];
    [upBwField setStringValue:@""];
    [downBwField setStringValue:@""];
    [fileQuotaField setStringValue:@""];
    [sizeQuotaField setStringValue:@""];
    [denyClientField setStringValue:@""];
    [allowClientField setStringValue:@""];
}




#pragma mark User methods

- (BOOL)isDuplicated:(VirtualUser *)user
{
    NSDictionary *compareDict = nil;
    switch(currentUserManager){
        case PureDB:
            compareDict = [pureUM compareUsersDictionary];
            break;
        case MySQL:
            compareDict = [mySQLUM compareUsersDictionary];
            break;
    }
    
    NSEnumerator *usersDictionaryEnum = [compareDict objectEnumerator];
    VirtualUser *existingUser;
    
    while (existingUser = [usersDictionaryEnum nextObject])
    {
        if ([[user login] isEqualToString:[existingUser login]]){
            NSString *format, *string;
            format = NSLocalizedString(@"%@ already exists on your system, please specify another username.", @"-username- already exists on your system, please specify another username.");
            string = [NSString stringWithFormat:format, [user login]];
            NSRunAlertPanel(NSLocalizedString(@"Duplicated Account !",@"Duplicated Account !"), 
                            string, 
                            NSLocalizedString(@"OK",@"OK"), NULL, NULL);
            return YES;
        }
    }
    return NO;
}

-(void) getUserInfoFor:(VirtualUser*) user
{
    
    [self clearFields];
    int timeBeginHours;
    int timeBeginMinutes;
    int timeEndHours;
    int timeEndMinutes;

    currentUser = user;
    
    if(revertedUser)
        [revertedUser release];
    
    revertedUser = [user copy];
    
    if (![user isNewUser])
    {
        [loginField setEnabled:NO];
        [passwordField setEnabled:NO];
    }
    else
    {
        [loginField setEnabled:YES];
        [passwordField setEnabled:YES];
    }
	
	if ([user isActivated])
	{
		[activationSwitch setState:NSOnState];
	} else {
		[activationSwitch setState:NSOffState];
	}
    
    [fullNameField setStringValue:[user gecos]];
    [loginField setStringValue:[user login]];
    
    [passwordField setStringValue:[user pwd]];
    
    if([[[user home] lastPathComponent] isEqualToString:@"."])
    {
        [chrootSwitch setState:1];
        [homeDirField setStringValue:[[user home] stringByDeletingLastPathComponent]];
    }
    else if ([user isNewUser]) {
        [chrootSwitch setState:1];
        [homeDirField setStringValue:[user home]];
    }
    else
    {
        NSString *lastComponent=[[user home] lastPathComponent];
        NSString *path = [[user home] stringByDeletingLastPathComponent];
        [chrootSwitch setState:0];
        
        [homeDirField setStringValue:[path stringByAppendingFormat:@"/%@", lastComponent]];
    }
    
    if (!([[user time_begin] isEqualToString:@""]) && !([[user time_end] isEqualToString:@""]) ){
        
        timeBeginHours = [[[user time_begin] substringWithRange:NSMakeRange(0,2)] intValue];
        timeBeginMinutes= [[[user time_begin] substringFromIndex:2] intValue];
        timeEndHours= [[[user time_end] substringWithRange:NSMakeRange(0,2)] intValue];
        timeEndMinutes = [[[user time_end] substringFromIndex:2] intValue];
        
        
        [timeBeginControl setHour:timeBeginHours];
        [timeBeginControl setMinute:timeBeginMinutes];
        [timeEndControl setHour:timeEndHours];
        [timeEndControl setMinute:timeEndMinutes];
        
        [timeAccessSwitch setState:NSOnState];
        //[timeAccessSwitch setTitle:NSLocalizedString(@"Enabled",@"Enabled")];
		[timeBeginControl setEnabled:YES];
        [timeEndControl setEnabled:YES];
        [timeAccessField setTextColor:[NSColor blackColor]];
		//[[timeBeginControl stepper] setEnabled:YES];
        //[[timeEndControl stepper] setEnabled:YES];
    }
    
    else {
        
        /*NSCalendarDate *cDate = [NSCalendarDate calendarDate];
        
        [timeBeginControl setHour:[cDate hourOfDay]];
        [timeBeginControl setMinute:[cDate minuteOfHour]];
        [timeEndControl setHour:[cDate hourOfDay]];
        [timeEndControl setMinute:[cDate minuteOfHour]];
        */
        [timeAccessSwitch setState:NSOffState];
        //[timeAccessSwitch setTitle:NSLocalizedString(@"Disabled",@"Disabled")];
		[timeAccessField setTextColor:[NSColor disabledControlTextColor]];
		[timeBeginControl setEnabled:NO];
        [timeEndControl setEnabled:NO];
       // [[timeBeginControl stepper] setEnabled:NO];
        //[[timeEndControl stepper] setEnabled:NO];
    }
    
    // User and Group (System)
    [userPopUp selectItemAtIndex:[userPopUp indexOfItemWithTag:[[user uid] intValue]]];
    [groupPopUp selectItemAtIndex:[groupPopUp indexOfItemWithTag:[[user gid] intValue]]];

    [maxSessionsField setStringValue:[user per_user_max]];
    [upRatioField setStringValue:[user ul_ratio]];
    [downRatioField setStringValue:[user dl_ratio]];
    [upBwField setStringValue:[user bw_ul]];
    [downBwField setStringValue:[user bw_dl]];
    [fileQuotaField setStringValue:[user quota_files]];
    [sizeQuotaField setStringValue:[user quota_size]];
    
    // Welcome message
    
    if (![[user banner] isEqualToString:@""]){
        [bannerTextView setString:[user banner]];
        [removeBannerBtn setEnabled:YES];
    }else{
        [bannerTextView setString:@""];
        [removeBannerBtn setEnabled:NO];
    }
    
    // IP Filtering
    [allowClientField setStringValue:@""];
    [denyClientField setStringValue:@""];
    
    
    // Virtual Folders
    if (![currentUser isNewUser])   {
         //[NSThread detachNewThreadSelector:@selector(refreshVFolderList) toTarget:self withObject:nil];
        [self refreshVFolderList];
    }
    

}

- (VirtualUser *)currentUser{
    return currentUser;
}

#pragma mark Creating / Saving / Deleting Users
- (void)createUser
{
    if (currentUserManager == PureDB){
        [pureUM createNewUser];
    } else if (currentUserManager == MySQL){
        [mySQLUM createUser];
    }
    
    [self synchronizeUserDB];
    //[userTable selectRow:[myUsersDictionary count]-1 byExtendingSelection:NO];
    [self selectRowWithName:NSLocalizedString(@"New User", @"New User")];
	[userTabView selectTabViewItemAtIndex:0];
}


- (void)deleteUser
{
    int selectedRow = [userTable selectedRow];
    NSString *msg = NSLocalizedString(@"You are about to delete user: %@.", @"You are about to delete user: %@.");
			
    if (currentUserManager == PureDB){
        if ([currentUser isNewUser]){
			NSString *username = NSLocalizedString(@"New User", @"New User") ;
			NSString *title = [NSString stringWithFormat:msg, username];
			if (NSRunCriticalAlertPanel(title,
							NSLocalizedString(@"Are you sure you want to continue ?",@"Are you sure you want to continue ?"),
							NSLocalizedString(@"Yes",@"Yes"),NSLocalizedString(@"No",@"No"),nil) != NSOKButton)
				return;
				
            [[pureUM usersDictionary] removeObjectForKey:username];
        } else {
			NSString *username = [currentUser login] ;
			NSString *title = [NSString stringWithFormat:msg, username];
			if (NSRunCriticalAlertPanel(title,
							NSLocalizedString(@"Are you sure you want to continue ?",@"Are you sure you want to continue ?"),
							NSLocalizedString(@"Yes",@"Yes"),NSLocalizedString(@"No",@"No"),nil) != NSOKButton)
				return;
            [[pureUM usersDictionary] removeObjectForKey:[currentUser login]];
            [pureUM writePasswdFile];
        }
    } else if (currentUserManager == MySQL){
        if ([currentUser isNewUser]){
			NSString *username = NSLocalizedString(@"New User", @"New User") ;
			NSString *title = [NSString stringWithFormat:msg, username];
			if (NSRunCriticalAlertPanel(title,
							NSLocalizedString(@"Are you sure you want to continue ?",@"Are you sure you want to continue ?"),
							NSLocalizedString(@"Yes",@"Yes"),NSLocalizedString(@"No",@"No"),nil) != NSOKButton)
				return;
				
            [[mySQLUM usersDictionary] removeObjectForKey:NSLocalizedString(@"New User", @"New User")];
        } else {
			NSString *username = [currentUser login] ;
			NSString *title = [NSString stringWithFormat:msg, username];
			if (NSRunCriticalAlertPanel(title,
							NSLocalizedString(@"Are you sure you want to continue ?",@"Are you sure you want to continue ?"),
							NSLocalizedString(@"Yes",@"Yes"),NSLocalizedString(@"No",@"No"),nil) != NSOKButton)
				return;
            [mySQLUM deleteUser:currentUser];
        }
    }
    
    currentUser = nil;
    
    [self synchronizeUserDB];
    int numberOfUsers = [sortedArray count];
    if (numberOfUsers>0)
    {
        selectedRow--;
        if (selectedRow < 0)
            selectedRow = 0;
        
        [userTable selectRow:selectedRow byExtendingSelection:NO];
    }
}

- (void)saveUser
{
    //int selectedRow = [userTable selectedRow];
    NSString *login = [currentUser login];
	NSString *home = nil;//[currentUser home];
	
	if([[[currentUser home] lastPathComponent] isEqualToString:@"."])
    {
        home = [[currentUser home] stringByDeletingLastPathComponent];
    }
    else
    {
        NSString *lastComponent=[[currentUser home] lastPathComponent];
        NSString *path = [[currentUser home] stringByDeletingLastPathComponent];
        
        home = [path stringByAppendingFormat:@"/%@", lastComponent];
    }
	
	BOOL isDir = NO;
	
	if ([[NSFileManager defaultManager] fileExistsAtPath:home isDirectory:&isDir] && isDir )
	{
		int uid=[[userPopUp selectedItem] tag];
		int gid=[[groupPopUp selectedItem] tag];
		
		NSString *uname=[userPopUp titleOfSelectedItem];
		NSString *gname=[groupPopUp titleOfSelectedItem];
		
		
		NSDictionary *dict=[NSDictionary dictionaryWithObjectsAndKeys:
							 uname, NSFileOwnerAccountName,
							gname, NSFileGroupOwnerAccountName, nil];
		
		NSNumber *p_uid=[[[NSFileManager defaultManager] fileAttributesAtPath:[home stringByDeletingLastPathComponent]
																traverseLink:YES]
									objectForKey:NSFileOwnerAccountID];
		
		NSDictionary *p_dict=[NSDictionary dictionaryWithObjectsAndKeys:
							@"root", NSFileOwnerAccountName, @"wheel",NSFileGroupOwnerAccountName, nil];
		
		
		//NSLog(@"%@, %d", [home stringByDeletingLastPathComponent], [p_uid intValue]);
		
		if (uid == [p_uid intValue])
		{
			NSString *msg=[NSString stringWithFormat:NSLocalizedString(@"Your virtual user home directory (%@) and its parent directory (%@) belong to the same system user.\n To fix the parent folder ownership to root:wheel, click Fix & Continue.", @"Your virtual user home directory (/home/dir) and its parent directory (/home) belong to the same system user.\n To fix the parent folder ownership to root:wheel, click Fix & Continue."), 
							home, [home stringByDeletingLastPathComponent]];
			int ret = NSRunAlertPanel(NSLocalizedString(@"File access warning", @"File access warning"),
								msg,
								NSLocalizedString(@"Fix & Continue", @"Fix & Continue"),
								NSLocalizedString(@"Cancel", @"Cancel"),
								NSLocalizedString(@"Continue", @"Continue"));
			if (ret == NSAlertAlternateReturn) {
				return;
			} else if (ret == NSAlertDefaultReturn){
				[[NSFileManager defaultManager] changeFileAttributes:p_dict atPath:[home stringByDeletingLastPathComponent]];
			}
			
		}
		[[NSFileManager defaultManager] changeFileAttributes:dict atPath:home];
	}
	
    if (currentUserManager == PureDB){
        [pureUM writePasswdFile];
    } else if (currentUserManager == MySQL){
        [mySQLUM saveUser:currentUser];
    }
    

	
    [self synchronizeUserDB];
    //[userTable selectRow:selectedRow byExtendingSelection:NO];
     [self selectRowWithName:login];
}

-(void) saveAlert
{
    NSBeginAlertSheet(NSLocalizedString(@"Virtual Users have been modified",@"Virtual Users have been modified"), 
                      NSLocalizedString(@"Save",@"Save"), 
                      NSLocalizedString(@"Cancel",@"Cancel"),  
                      NSLocalizedString(@"Revert",@"Revert"),
                      [NSApp mainWindow], self, @selector(sheetDidEnd:returnCode:contextInfo:), 
                      NULL, NULL, 
                      NSLocalizedString(@"Would you like to apply these changes to PureFTPd ?",@"localized string"),
                      nil);
    NSModalSession session = [NSApp beginModalSessionForWindow:[NSApp mainWindow]];
    for (;;) {
        if ([NSApp runModalSession:session] != NSRunContinuesResponse)
            break;
    }
    [NSApp endModalSession:session];
}


- (void)sheetDidEnd: (NSWindow *)sheet
         returnCode: (int)returnCode
        contextInfo: (void *)contextInfo
{
    /*NSMutableArray *keyArray = [NSMutableArray arrayWithArray:[myUsersDictionary allKeys]];
    VirtualUser *user = [[pureUM usersDictionary] objectForKey:[keyArray objectAtIndex:[userTable selectedRow]]];
    */
    if (returnCode == NSAlertDefaultReturn)
    {
        [self saveUser];
        [pureController setSelectNow:YES];
    }
    else if (returnCode == NSAlertOtherReturn)
    {
        switch (currentUserManager){
            case PureDB:
                [[pureUM usersDictionary] setObject:revertedUser forKey:[currentUser login]];
                break;
            case MySQL:
                [[mySQLUM usersDictionary] setObject:revertedUser forKey:[currentUser login]];
                break;
        }

        [self synchronizeUserDB];
        [self disableUserFields];
        //[self getUserInfoFor:revertedUser];
        [pureController setSelectNow:YES];
    }
    else if (returnCode == NSAlertAlternateReturn)
    {
        [pureController setSelectNow:NO];
    }
    
    [NSApp stopModal];
}



#pragma mark Synchronize controller with User Database
- (void)synchronizeUserDB
{
    /*if (myUsersDictionary)
        [myUsersDictionary release];
    */
    if (currentUserManager == PureDB){
        myUsersDictionary = [pureUM usersDictionary];//[[NSMutableDictionary alloc] initWithDictionary:[pureUM usersDictionary]];
    } else if (currentUserManager == MySQL){
        //NSLog(@"synchronizeUserDB MySQL");
        myUsersDictionary = [mySQLUM usersDictionary];//[[NSMutableDictionary alloc] initWithDictionary:[mySQLUM usersDictionary]];
    }
    
    // Sort user by name
    NSMutableArray *keyArray = [NSArray arrayWithArray:[myUsersDictionary allKeys]];
    NSMutableArray *usersArray = [[NSMutableArray alloc] init];
    NSEnumerator *keyEnum = [keyArray objectEnumerator];
    NSString *key = nil;
    while(key = [keyEnum nextObject]){
        NSDictionary *aDict = [NSDictionary dictionaryWithObject:key forKey:@"account"];
        [usersArray addObject:aDict];
    }
    
    
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/etc/pure-ftpd/pure-ftpd.plist"];
    if ([[prefs objectForKey:OSVersion] intValue] >= 0x1030)
    {
        
        NSSortDescriptor *lastNameDescriptor=[[[NSSortDescriptor alloc] initWithKey:@"account" 
                                                                          ascending:YES
                                                                           selector:@selector(caseInsensitiveCompare:)] autorelease];
        NSArray *sortDescriptors=[NSArray arrayWithObject:lastNameDescriptor];
        
        if (sortedArray)
            [sortedArray release];
        sortedArray=[[NSArray alloc] initWithArray:[usersArray sortedArrayUsingDescriptors:sortDescriptors]];
    } else {
        if (sortedArray)
            [sortedArray release];
        sortedArray = [[NSArray alloc] initWithArray:usersArray];
    }
    
    [usersArray release];
    
    [userTable reloadData];
    [userTable deselectAll:nil];
}

- (void)selectRowWithName:(NSString *)name
{
    NSString *match = name;
    int numberOfRows = [sortedArray count];
   
    // row we will select
    int rowToSelect=0;
    int j = 0;
    
    for (j=0; j<numberOfRows; j++)
    {
        VirtualUser *user = [myUsersDictionary objectForKey:[[sortedArray objectAtIndex:j] objectForKey:@"account"]];
        if ([[user login] isEqualToString:match]){
            rowToSelect = j;
            goto selectNow;
        }
    }

selectNow:
        [userTable selectRow:rowToSelect byExtendingSelection:NO];
    
}

#pragma mark NSTextView delegates
- (void)textDidChange:(NSNotification *)aNotification
{
    if ([[aNotification object] isEqualTo:bannerTextView]){
        [currentUser setBanner:[bannerTextView string]];
        [currentUser setHasBeenEdited:YES];
        [removeBannerBtn setEnabled:YES];
    }
}

#pragma mark NSTextField delegates
- (void)controlTextDidEndEditing:(NSNotification *)aNotification
{
    if([[aNotification object] isEqualTo:loginField]){
        /* lastPathComponent */
        if ([self isDuplicated:currentUser])
            return;
        NSString *lpc = [[[NSMutableDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile] objectForKey:PureFTPUserBaseDir] lastPathComponent] ;
        
        
        if ( [[[homeDirField stringValue] lastPathComponent] isEqualToString:lpc] )
            [homeDirField setStringValue:[[homeDirField stringValue] stringByAppendingFormat:@"/%@", [[aNotification object] stringValue]]];
        else
        {
            [homeDirField setStringValue:[[homeDirField stringValue] stringByDeletingLastPathComponent]];
            [homeDirField setStringValue:[[homeDirField stringValue] stringByAppendingFormat:@"/%@", [[aNotification object] stringValue]]];
        }
        
        if ([chrootSwitch state] == 1)
        {
            [currentUser setHome:[[homeDirField stringValue] stringByAppendingString:@"/./"]];
        }
        else
            [currentUser setHome:[[homeDirField stringValue] stringByAppendingString:@"/"]];
    }
    
    else if([[aNotification object] isEqualTo:timeBeginControl])
    {
	if([timeAccessSwitch state] == NSOnState) {
            [currentUser setTimeBegin: [NSString stringWithFormat:@"%02d%02d", 
                [[aNotification object] hour],
                [[aNotification object] minute]]];
        }
        else
            [currentUser setTimeBegin:@""];
    }
    
    else if([[aNotification object] isEqualTo:timeEndControl])
    {
        if ([timeAccessSwitch state] == NSOnState) {
            [currentUser setTimeEnd:[NSString stringWithFormat:@"%02d%02d", 
                [[aNotification object] hour],
                [[aNotification object] minute]]];
        }
        else 
            [currentUser setTimeEnd:@""];
    } else if ([[aNotification object] isEqualTo:homeDirField]){
		[self refreshVFolderList];
	}
    [currentUser setHasBeenEdited:YES];
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    if ([[aNotification object] isEqualTo:fullNameField])
        [currentUser setGecos:[fullNameField stringValue]];
    
    else if([[aNotification object] isEqualTo:loginField]){
        [currentUser setLogin:[[aNotification object] stringValue]];
    }
    
    else if([[aNotification object] isEqualTo:passwordField])
        [currentUser setPwd:[[aNotification object] stringValue]];
    
    else if([[aNotification object] isEqualTo:homeDirField])
    {
        if ([chrootSwitch state] == 1)
        {
            [currentUser setHome:[[[aNotification object] stringValue] stringByAppendingString:@"/./"]];
        }
        else
            [currentUser setHome:[[[aNotification object] stringValue] stringByAppendingString:@"/"]];
    }
    
    else if([[aNotification object] isEqualTo:maxSessionsField])
        [currentUser setUserMax:[[aNotification object] stringValue]];
    
    else if([[aNotification object] isEqualTo:upRatioField])
    {
        [currentUser setUl_ratio:[[aNotification object] stringValue]];
    }    
    
    else if([[aNotification object] isEqualTo:downRatioField])
    {
        [currentUser setDl_ratio:[[aNotification object] stringValue]];
    }
    
    else if([[aNotification object] isEqualTo:upBwField])
    {
        [currentUser setBw_ul:[[aNotification object] stringValue]];
    }
    
    else if([[aNotification object] isEqualTo:downBwField])
    {
        [currentUser setBw_dl:[[aNotification object] stringValue]];
    }
    
    else if([[aNotification object] isEqualTo:fileQuotaField])
        [currentUser setQuotaFiles:[[aNotification object] stringValue]];
    
    else if([[aNotification object] isEqualTo:sizeQuotaField])
        [currentUser setQuotaSize:[[aNotification object] stringValue]];
    
     [currentUser setHasBeenEdited:YES];
}




#pragma mark NSTableViews Delegate & DataSource functions
- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
    if ([tableView isEqualTo: userTable]){
        return [sortedArray count];
    }else if ([tableView isEqualTo: allowClientTable]){
        if (nil != currentUser) {
            return [[currentUser allow_client_ip] count];
        }
        else 
            return 0;
    }else if ([tableView isEqualTo: denyClientTable]){
        if (nil != currentUser) {
            return [[currentUser deny_client_ip] count];
        }
        else 
            return 0;
    } else if ([tableView isEqualTo: vfolderTable]){
        if (nil != currentUser) {
            return [userVFolderList count];
        }
        else 
            return 0;
    }
    return 0;
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn *)col row:(int)row
{
   
    if ([tableView isEqualTo:userTable]){
        //NSMutableArray *keyArray = [NSMutableArray arrayWithArray:[myUsersDictionary allKeys]];
        VirtualUser *user = [myUsersDictionary objectForKey:[[sortedArray objectAtIndex:row] objectForKey:@"account"]];
        return [user login];
    } else if ([tableView isEqualTo:allowClientTable]) {
        if (nil != currentUser){
            return  [[currentUser allow_client_ip] objectAtIndex:row];
        } else {
            return nil;
        }
       
    } else if ([tableView isEqualTo:denyClientTable] && ([userTable selectedRow] != -1))
    {
        if (nil != currentUser){
            return  [[currentUser deny_client_ip] objectAtIndex:row];
        } else {
            return nil;
        }
    } else if ([tableView isEqualTo:vfolderTable] && (nil != currentUser)){
        return [userVFolderList objectAtIndex:row];
    } 
    
    
    return nil;
}

// userTable delegates

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    /*VirtualUser *user = nil;
    
    if ([tableView isEqualTo: userTable])
    {
	if (row ==-1)
	    //NSLog(@"-1");
	if ([userTable selectedRow] !=-1)
	    user = [myUsers objectAtIndex:[tableView selectedRow]];
            
	if ((user != nil) && (![self hasEnoughInfoForUser:user]))
	{
            //[myUsers removeObjectAtIndex:[tableView selectedRow]];
            //[userTable reloadData];
	   //return NO;
	}
    }*/
    
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //NSMutableArray *keyArray = [NSMutableArray arrayWithArray:[myUsersDictionary allKeys]];
    if([[notification object] isEqualTo: userTable]){
        int index = -1;
        if((index = [userTable selectedRow]) != -1){
            NSDictionary *userInfo = [sortedArray objectAtIndex:index];
            if (userInfo != nil)
            {   
                VirtualUser *user = [myUsersDictionary objectForKey:[userInfo objectForKey:@"account"]];
                if (nil != user){
                    [self getUserInfoFor:user];
                    [self enableUserFields];
                }
            }
        } else {
            currentUser = nil;
            [self disableUserFields];
            [self refreshVFolderList];
        }
        
	[allowClientTable reloadData];  
	[denyClientTable reloadData];
    } else if([[notification object] isEqualTo: allowClientTable]){
	if ([allowClientTable selectedRow] != -1){
	    [allowClientRemoveButton setEnabled:YES];
	}else{
	    [allowClientRemoveButton setEnabled:NO];
	}
    } else if([[notification object] isEqualTo: denyClientTable]){
	if([denyClientTable selectedRow] != -1){
	    [denyClientRemoveButton setEnabled:YES];
	}else{
	    [denyClientRemoveButton setEnabled:NO];
	}
    } else if([[notification object] isEqualTo: vfolderTable]){
	if([vfolderTable selectedRow] != -1){
            NSString *lpc =  [userVFolderList objectAtIndex:[vfolderTable selectedRow]];
            NSString *fullPath =  [[NSString stringWithFormat:@"%@/%@", [currentUser home], lpc] stringByResolvingSymlinksInPath];
            [fileBrowser setPath:fullPath];
	    [vfolderRemoveButton setEnabled:YES];
            [vfolderAccessButton setEnabled:YES];
            [accessPopUp setEnabled:YES];
            [self getAccessToFolder:fullPath];
            
	}else{
            [fileBrowser setPath:@"/"];
	    [vfolderRemoveButton setEnabled:NO];
            [vfolderAccessButton setEnabled:NO];
            [accessPopUp setEnabled:NO];
	}
    }
    
}




@end
