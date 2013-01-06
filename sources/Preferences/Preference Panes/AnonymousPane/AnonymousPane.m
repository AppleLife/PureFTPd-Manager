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

#import "AnonymousPane.h"
#import "defines.h"
#include <sys/types.h>
#include <pwd.h>
#import "AFSNodeInfo.h"
#import "AFSBrowserCell.h"

#import "NSFileManager+ASExtensions.h"

#define MAX_VISIBLE_COLUMNS 3

@interface AnonymousPane (PrivateUtilities)
- (NSString*)fsPathToColumn:(int)column;
@end

@implementation AnonymousPane (PrivateUtilities)

- (NSString*)fsPathToColumn:(int)column {
    NSString *path = nil;
    if(column==0) path = [NSString stringWithFormat: @"/"];
    else path = [fileBrowser pathToColumn: column];
    return path;
}

@end

@implementation AnonymousPane
- (id) initWithBundle:(NSBundle *) bundle {
    self = [super initWithBundle:bundle] ;
    return self ;
}

- (void) dealloc {
    if (userVFolderList)
        [userVFolderList release];
    [super dealloc];
}

-(void) loadPreferences{
    [anonNoAccessSwitch setState:[[pureFTPPreferences objectForKey:PureFTPNoAnonymous] intValue]];
    [anonCreateDirSwitch setState:[[pureFTPPreferences objectForKey:PureFTPAnonymousCreateDir] intValue]];
    [anonNoUpSwitch setState:[[pureFTPPreferences objectForKey:PureFTPAnonymousNoUpload] intValue]];
    [anonNoDownSwitch setState:[[pureFTPPreferences objectForKey:PureFTPAnonymousNoDownload] intValue]];
    
    //Anon Ratio
    if (!([[pureFTPPreferences objectForKey:PureFTPAnonymousRatio] isEqualToString:@""]))
    {
        NSArray *anonRatio = [NSArray arrayWithArray:[[pureFTPPreferences objectForKey:PureFTPAnonymousRatio] componentsSeparatedByString:@":"]];
        int upratio = [[anonRatio objectAtIndex:0] doubleValue];
		int downratio = [[anonRatio objectAtIndex:1] doubleValue];
	
	if(upratio != 0)
	    [anonUpRatioField setStringValue:[NSString stringWithFormat:@"%d", upratio]];
	else
	    [anonUpRatioField setStringValue:@""];
	
        if(downratio != 0)
	    [anonDownRatioField setStringValue:[NSString stringWithFormat:@"%d", downratio]];
	else
	    [anonDownRatioField setStringValue:@""];
    }
    
    //Anon BW
    if (!([[pureFTPPreferences objectForKey:PureFTPAnonymousSpeedLimit] isEqualToString:@""]))
    {
        NSArray *speed = [NSArray arrayWithArray:[[pureFTPPreferences objectForKey:PureFTPAnonymousSpeedLimit] componentsSeparatedByString:@":"]];
	int upbw = [[speed objectAtIndex:0] intValue];
	int downbw = [[speed objectAtIndex:1] intValue];
	
	if(upbw != 0)
	    [anonUpBWField setStringValue:[NSString stringWithFormat:@"%d", upbw]];
	else
	    [anonUpBWField setStringValue:@""];
	
	if(downbw != 0)
	    [anonDownBWField setStringValue:[NSString stringWithFormat:@"%d", downbw]];
	else
	    [anonDownBWField setStringValue:@""];
    }
    
    [maxLoadField setStringValue:[pureFTPPreferences objectForKey:PureFTPMaxLoad]];
    
    [self loadBanner];
	
	struct passwd *userInfo = NULL;
	if ((userInfo = getpwnam("ftp")) != NULL)
	{
		[homeDirField setStringValue:[NSString stringWithCString:userInfo->pw_dir]];
	}
	homeDirSet = NO;
}

-(void) savePreferences{
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    
    NSNumber *anonNoAccess = [[NSNumber alloc] initWithInt:[anonNoAccessSwitch state]];
    NSNumber *anonCreateDir = [[NSNumber alloc] initWithInt:[anonCreateDirSwitch state]];
    NSNumber *anonNoUp = [[NSNumber alloc] initWithInt:[anonNoUpSwitch state]];
    NSNumber *anonNoDown = [[NSNumber alloc] initWithInt:[anonNoDownSwitch state]]; 
    // Get Anonymous speed limit
    NSString *anonSpeedLimit;
    if ([[anonDownBWField stringValue] isEqualTo:@""] ||
        [[anonUpBWField stringValue] isEqualTo:@""] ){
        anonSpeedLimit=@"";
    } else {
        NSNumber *up = [NSNumber numberWithDouble:[anonUpBWField intValue]];
        NSNumber *down = [NSNumber numberWithDouble:[anonDownBWField intValue]];
        anonSpeedLimit=[NSString stringWithFormat:@"%@:%@", up , down ];
    }
        
    // Get anonymous Ratio
    NSString *anonRatio;
    if ([[anonDownRatioField stringValue] isEqualTo:@""] ||
        [[anonUpRatioField stringValue] isEqualTo:@""] ){
        anonRatio=@"";
    } else {
		NSNumber *up = [NSNumber numberWithDouble:[anonUpRatioField doubleValue]];
        NSNumber *down = [NSNumber numberWithDouble:[anonDownRatioField doubleValue]];
        anonRatio=[NSString stringWithFormat:@"%@:%@", up , down ];
    }
         
    [preferences setObject:anonNoAccess forKey:PureFTPNoAnonymous];
    [preferences setObject:anonCreateDir forKey:PureFTPAnonymousCreateDir];
    [preferences setObject:anonNoUp forKey:PureFTPAnonymousNoUpload];
    [preferences setObject:anonNoDown forKey:PureFTPAnonymousNoDownload];
    [preferences setObject:[maxLoadField stringValue] forKey:PureFTPMaxLoad];
    [preferences setObject:anonRatio forKey:PureFTPAnonymousRatio];
    [preferences setObject:anonSpeedLimit forKey:PureFTPAnonymousSpeedLimit];
    
    NSNumber *update = [[NSNumber alloc] initWithInt:1];
    [preferences setObject:update forKey:PureFTPPrefsUpdated];
    
    //NSLog(@"Saving PureFTPD preferences - Anonymous Pane");
    [preferences writeToFile:PureFTPPreferenceFile atomically:YES];
    [preferences release];
    modified = NO;
    
}

#pragma mark Delegates
// TextFields
- (void)controlTextDidChange:(NSNotification *)aNotification
{
    if ([[aNotification object] isEqualTo:homeDirField] && !homeDirSet)
	{
		NSString *newHome=[homeDirField stringValue];
		
		NSTask *del = [[NSTask alloc] init];
		[del setLaunchPath:@"/usr/bin/niutil"];
		[del setArguments:[NSArray arrayWithObjects:@"-destroyprop", @"/", @"/users/ftp", @"home", nil]];
		[del launch];
		[del waitUntilExit];
		[del release];
		
		NSTask *add = [[NSTask alloc] init];
		[add setLaunchPath:@"/usr/bin/niutil"];
		[add setArguments:[NSArray arrayWithObjects:@"-createprop", @"/", @"/users/ftp", @"home", newHome, nil]];
		[add launch];
		
		[add release];
		
		// change dir to root:wheel
		NSDictionary *p_dict=[NSDictionary dictionaryWithObjectsAndKeys:
							@"root", NSFileOwnerAccountName, @"wheel",NSFileGroupOwnerAccountName, nil];
							
		NSFileManager *_fm = [NSFileManager defaultManager];
		[_fm changeFileAttributes:p_dict atPath:newHome];
		
		// create incoming directory
		NSString *inc=[newHome stringByAppendingPathComponent:@"incoming"];
		NSDictionary *dict=[NSDictionary dictionaryWithObjectsAndKeys:
							@"ftp", NSFileOwnerAccountName, @"unknown", NSFileGroupOwnerAccountName, 
							[NSNumber numberWithInt:0755], NSFilePosixPermissions, nil];
		BOOL isDir = YES;
		if ([_fm fileExistsAtPath:inc isDirectory:&isDir] && isDir)
			[_fm changeFileAttributes:dict atPath:inc];
		else	
			[_fm createDirectoryAtPath:inc attributes:dict];
		
		homeDirSet = YES;
	} else {
		modified = YES;
	}
}

- (IBAction)didModify:(id)sender
{
    modified = YES;
}

- (void) loadBanner
{
    NSString *bannerPath = [homeDirectory stringByAppendingPathComponent:@".banner"];
    NSString *banner = nil;
    if ([fm fileExistsAtPath:bannerPath]){
        banner = [NSString stringWithContentsOfFile:bannerPath];
        [bannerTxtView setString:banner];
    } else {
        [removeBannerBtn setEnabled:NO];
    }
	
	
}

- (void) saveBanner 
{
    NSString *bannerPath = [homeDirectory stringByAppendingPathComponent:@".banner"];
    NSString *banner = [NSString stringWithString:[bannerTxtView string]];
    
    if (![banner isEqualToString:@""]) {
        [banner writeToFile:bannerPath atomically:YES];
        [removeBannerBtn setEnabled:YES];
    } else {
        [self removeBanner:nil];
    }
}


- (IBAction)removeBanner:(id)sender
{
    NSString *bannerPath = [homeDirectory stringByAppendingPathComponent:@".banner"];
    [fm removeFileAtPath:bannerPath handler:nil];
    [bannerTxtView setString:@""];
    [removeBannerBtn setEnabled:NO];
}

- (void) mainViewDidLoad {
    pureFTPPreferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    
    userVFolderList = [[NSMutableArray alloc] init];
     modified=NO;
     struct passwd *userInfo;
     
     if ( (userInfo = getpwnam("ftp")) != NULL){
         homeDirectory = [[NSString alloc] initWithFormat:@"%s", userInfo->pw_dir];
     } else {
         homeDirectory = [[NSString alloc] initWithString:@"/tmp"];
     }
     
     fm = [NSFileManager defaultManager];
     [self loadPreferences];  
     
     // Make the browser user our custom browser cell.
     [fileBrowser setCellClass: [AFSBrowserCell class]];
     
     // Tell the browser to send us messages when it is clicked.
     [fileBrowser setTarget: self];
     [fileBrowser setAction: @selector(browserSingleClick:)];
     [fileBrowser setDoubleAction: @selector(browserDoubleClick:)];
     
     // Configure the number of visible columns (default max visible columns is 1).
     [fileBrowser setMaxVisibleColumns: MAX_VISIBLE_COLUMNS];
     [fileBrowser setMinColumnWidth: NSWidth([fileBrowser bounds])/(float)MAX_VISIBLE_COLUMNS];
     
     // Prime the browser with an initial load of data.
     [self reloadBrowserData: nil];
      [self refreshVFolderList];
}

- (void) willUnselect {
    if(modified) {
        [self savePreferences];    
    } 
    [pureFTPPreferences release];    
    
    if ([fm fileExistsAtPath:homeDirectory]){
        [self saveBanner];
    } else {
        NSNumber *permissions = [NSNumber numberWithInt:0555];
        NSArray *objects = [NSArray arrayWithObjects:permissions, @"ftp", @"unknown", nil];
        NSArray *keys = [NSArray arrayWithObjects:NSFilePosixPermissions, NSFileOwnerAccountName, NSFileGroupOwnerAccountName, nil];
        NSDictionary *posixAttributes = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
        [fm createDirectoryAtPath:homeDirectory attributes:posixAttributes recursive:YES];
        [self saveBanner];
    }
    
    [homeDirectory release];
}

- (IBAction)reloadBrowserData:(id)sender {
    [fileBrowser loadColumnZero];
}

// ==========================================================
#pragma mark Browser Delegate Methods.
// ==========================================================

// Use lazy initialization, since we don't want to touch the file system too much.
- (int)browser:(NSBrowser *)sender numberOfRowsInColumn:(int)column {
    NSString   *fsNodePath = nil;
    AFSNodeInfo *fsNodeInfo = nil;
    
    // Get the absolute path represented by the browser selection, and create a fsnode for the path.
    // Since column represents the column being (lazily) loaded fsNodePath is the path for the last selected cell.
    fsNodePath = [self fsPathToColumn: column];
    fsNodeInfo = [AFSNodeInfo nodeWithParent: nil atRelativePath: fsNodePath];
    
    return [[fsNodeInfo visibleSubNodes] count];
}

- (void)browser:(NSBrowser *)sender willDisplayCell:(id)cell atRow:(int)row column:(int)column {
    NSString   *containingDirPath = nil;
    AFSNodeInfo *containingDirNode = nil;
    AFSNodeInfo *displayedCellNode = nil;
    NSArray    *directoryContents = nil;
    
    // Get the absolute path represented by the browser selection, and create a fsnode for the path.
    // Since (row,column) represents the cell being displayed, containingDirPath is the path to it's containing directory.
    containingDirPath = [self fsPathToColumn: column];
    containingDirNode = [AFSNodeInfo nodeWithParent: nil atRelativePath: containingDirPath];
    
    // Ask the parent for a list of visible nodes so we can get at a AFSNodeInfo for the cell being displayed.
    // Then give the AFSNodeInfo to the cell so it can determine how to display itself.
    directoryContents = [containingDirNode visibleSubNodes];
    displayedCellNode = [directoryContents objectAtIndex: row];
    
    [cell setAttributedStringValueFromAFSNodeInfo: displayedCellNode];
}

// ==========================================================
#pragma mark Browser Target / Action Methods.
// ==========================================================

- (IBAction)browserSingleClick:(id)browser {
    
}

- (IBAction)browserDoubleClick:(id)browser {
    // Open the file and display it information by calling the single click routine.
    NSString *nodePath = [browser path];
    [self browserSingleClick: browser];
    //[[NSWorkspace sharedWorkspace] openFile: nodePath];
    
    
   
    
    
    //NSFileManager *fm = [NSFileManager defaultManager];
    //struct passwd *userInfo;
    //struct group *groupInfo;
    
    if (![fm fileExistsAtPath:homeDirectory] ){
        NSString *username = @"ftp";
        NSString *group = @"admin";
        
        NSNumber *permissions = [NSNumber numberWithInt:0475];
        NSArray *objects = [NSArray arrayWithObjects:permissions, username,  group, nil];
        NSArray *keys = [NSArray arrayWithObjects:NSFilePosixPermissions, NSFileOwnerAccountName, NSFileGroupOwnerAccountName, nil];
        NSDictionary *posixAttributes = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
        if (![fm createDirectoryAtPath:homeDirectory attributes:posixAttributes recursive:YES])
            return;
    }
    
    
    NSFileWrapper *fw = [[NSFileWrapper alloc] init];
    NSString *linkDest = [NSString stringWithFormat:@"%@/%@", homeDirectory, [nodePath lastPathComponent]];
    [fw initSymbolicLinkWithDestination:nodePath];
    [fw writeToFile:linkDest atomically:YES updateFilenames:NO];
    
    //    + (void)detachNewThreadSelector:(SEL)aSelector toTarget:(id)aTarget withObject:(id)anArgument
    //[NSThread detachNewThreadSelector:@selector(refreshVFolderList) toTarget:self withObject:nil];
    [self refreshVFolderList];
}

#pragma mark Virtual Folders detection / deletion
- (void)refreshVFolderList
{
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];   
    [userVFolderList removeAllObjects];
   
    
  //  NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath: homeDirectory]){
        NSArray *dirContent = [fm directoryContentsAtPath:homeDirectory];
        if(nil == dirContent)
            return;
        
        NSArray * contents = [NSArray arrayWithArray:dirContent];
        NSEnumerator *contentsEnum = [contents objectEnumerator];
        NSString *dirName;
        BOOL isDir;
        
        while(dirName = [contentsEnum nextObject]){
            NSString *fullPath = [homeDirectory stringByAppendingPathComponent:dirName];
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
  
    NSString *linkName = [userVFolderList objectAtIndex:[vfolderTable selectedRow]];
    NSString *linkPath = [homeDirectory stringByAppendingPathComponent:linkName];
    [[NSFileManager defaultManager] removeFileAtPath:linkPath handler:nil];
    
    //[NSThread detachNewThreadSelector:@selector(refreshVFolderList) toTarget:self withObject:nil];
    [self refreshVFolderList];
}

#pragma mark NSTableViews Delegate & DataSource functions
- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
   return [userVFolderList count];
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn *)col row:(int)row
{
    return [userVFolderList objectAtIndex:row];
}

// userTable delegates

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    //NSMutableArray *keyArray = [NSMutableArray arrayWithArray:[myUsersDictionary allKeys]];
    if([[notification object] isEqualTo: vfolderTable]){
	if([vfolderTable selectedRow] != -1){
            NSString *lpc =  [userVFolderList objectAtIndex:[vfolderTable selectedRow]];
            NSString *fullPath =  [[NSString stringWithFormat:@"%@/%@", homeDirectory, lpc] stringByResolvingSymlinksInPath];
            [fileBrowser setPath:fullPath];
	    [vfolderRemoveButton setEnabled:YES];
	}else{
            [fileBrowser setPath:@"/"];
	    [vfolderRemoveButton setEnabled:NO];
	}
    }
    
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
	
	NSString *path = [homeDirField stringValue];
	
	BOOL isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]
		|| !isDir)
		path=@"/"; 
		
	[oPanel beginSheetForDirectory:path file:nil types:nil
					modalForWindow:[NSApp mainWindow]
                       modalDelegate: self
                       didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo: nil];
    homeDirSet = NO;
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
    [NSApp stopModal];
    if (returnCode == NSOKButton)
    {        
        NSString *newHome=[[sheet filenames] objectAtIndex:0];
		homeDirSet = YES;
		[homeDirField setStringValue:newHome];
		
		NSTask *del = [[NSTask alloc] init];
		[del setLaunchPath:@"/usr/bin/niutil"];
		[del setArguments:[NSArray arrayWithObjects:@"-destroyprop", @"/", @"/users/ftp", @"home", nil]];
		[del launch];
		[del waitUntilExit];
		[del release];
		
		NSTask *add = [[NSTask alloc] init];
		[add setLaunchPath:@"/usr/bin/niutil"];
		[add setArguments:[NSArray arrayWithObjects:@"-createprop", @"/", @"/users/ftp", @"home", newHome, nil]];
		[add launch];
		
		[add release];
		
		// change dir to root:wheel
		NSDictionary *p_dict=[NSDictionary dictionaryWithObjectsAndKeys:
							@"root", NSFileOwnerAccountName, @"wheel",NSFileGroupOwnerAccountName, nil];
							
		NSFileManager *_fm = [NSFileManager defaultManager];
		[_fm changeFileAttributes:p_dict atPath:newHome];
		
		// create incoming directory
		NSString *inc=[newHome stringByAppendingPathComponent:@"incoming"];
		NSDictionary *dict=[NSDictionary dictionaryWithObjectsAndKeys:
							@"ftp", NSFileOwnerAccountName, @"unknown", NSFileGroupOwnerAccountName, 
							[NSNumber numberWithInt:0755], NSFilePosixPermissions, nil];
		BOOL isDir = YES;
		if ([_fm fileExistsAtPath:inc isDirectory:&isDir] && isDir)
			[_fm changeFileAttributes:dict atPath:inc];
		else	
			[_fm createDirectoryAtPath:inc attributes:dict];
		
    }   
        

}

@end

