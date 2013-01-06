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
#import "AKAnonymousPaneController.h"
#import "ManagerProcessEngine.h"


@implementation AKAnonymousPaneController

- (void) initPaneWithEngine:(id) inEngine
{
    [anonGroupPopUp removeAllItems];
    NSString *groupname;
    struct group *gInfo;
    while((gInfo=getgrent()) != NULL)
    {
        groupname = [NSString stringWithFormat:@"%s", gInfo->gr_name];
		if ([groupname characterAtIndex:0] == '_')
			continue;
        [anonGroupPopUp addItemWithTitle:groupname];
        [[anonGroupPopUp lastItem] setTag: gInfo->gr_gid];
    }
    SInt32 MacVersion;
    Gestalt(gestaltSystemVersion, &MacVersion);
	
	if (MacVersion < 0x1050){
		[anonGroupPopUp selectItemWithTitle:@"unknown"];
	} else {
		[anonGroupPopUp selectItemWithTitle:@"nobody"];
	}
}


- (BOOL) checkPaneValuesWithEngine:(id) inEngine
{
    NSMutableDictionary *myOptions = [inEngine wizardOptions];
    
    if ([anonSkipSwitch state] == NSOnState)
    {
        [myOptions setObject:[NSNumber numberWithInt:1] 
                     forKey: ANONSKIP];
  
        return YES;
    }
    else if (((![inEngine uniqUID:[anonUIDField intValue]]) || ([anonUIDField intValue] == 0)) && !([inEngine checkUID:[anonUIDField intValue] forUser:@"ftp"]))
    {
        NSRunAlertPanel(NSLocalizedString(@"You specified a UID that already exists!",@"UID exists"),
                        NSLocalizedString(@"Please choose another one",@"Please choose another one"),
                        NSLocalizedString(@"Ok",@"Ok"),
                        @"",nil);
        return NO;
    }
    else if (![inEngine uniqUser:@"ftp"] && ([inEngine checkUID:[anonUIDField intValue] forUser:@"ftp"]))
    {
        NSRunAlertPanel(NSLocalizedString(@"Anonymous account already present.",@"Login screen name exists"),
                        NSLocalizedString(@"The specified settings match an existing user on your computer (maybe it was already set up). It will be used to enable anonymous user access to you ftp server.",@"Anonymous account setup will be skipped"),
                        NSLocalizedString(@"OK",@"OK"),
                        @"",nil);
        
        [anonSkipSwitch setState:NSOnState];
        [myOptions setObject:[NSNumber numberWithInt:1] 
                      forKey: ANONSKIP];
        return YES;
    }
    else
    {
        [myOptions setObject:[NSNumber numberWithInt:0] 
                      forKey: ANONSKIP];
        [myOptions setObject:[anonHomeField stringValue]
                      forKey:ANONHOME];
        [myOptions setObject:[NSNumber numberWithInt:[[anonGroupPopUp selectedItem]  tag]]
                      forKey:ANONGROUP];
        [myOptions setObject:[NSNumber numberWithInt:[anonUIDField intValue]]
                      forKey:ANONUID];
        
        return YES;
    }
    
    
    return NO;
    
    
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
    
    [oPanel beginSheetForDirectory:NSHomeDirectory() file:nil types:nil 
                    modalForWindow:[NSApp mainWindow]
                     modalDelegate: self
                    didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo: nil];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
    [NSApp stopModal];
    if (returnCode == NSOKButton){
        [anonHomeField setStringValue: [[sheet filenames] objectAtIndex:0]];
    }
}


@end
