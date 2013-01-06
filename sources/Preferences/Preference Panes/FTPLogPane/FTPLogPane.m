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

#import "FTPLogPane.h"

@implementation FTPLogPane
- (id) initWithBundle:(NSBundle *) bundle {
    self = [super initWithBundle:bundle] ;
    
    return self ;
}

- (void) dealloc {
	[super dealloc];
}


- (void) loadPreferences {
    [logSwitch setState:[[pureFTPPreferences objectForKey:PureFTPLogOnOff] intValue]];
    [updateSwitch setState:[[pureFTPPreferences objectForKey:PureFTPLogAutoUpdate] intValue]];
    [shareSwitch setState:[[pureFTPPreferences objectForKey:PureFTPLogNiceThread] intValue]];
    
    if ([logSwitch state] == 1)
    {
	[formatPopUp setEnabled:YES];
	[locationField setEnabled:YES];
	[browseButton setEnabled:YES];
        [updateSwitch setEnabled:YES];
        [shareSwitch setEnabled:YES];
    }
    
    if ([pureFTPPreferences objectForKey:PureFTPLogFormat] != nil)
	[formatPopUp selectItemWithTitle:[pureFTPPreferences objectForKey:PureFTPLogFormat]];

    if ((lastLogFile=[pureFTPPreferences objectForKey:PureFTPLogLocation]) != nil)
    {
	[locationField setStringValue:lastLogFile];
    }
    
}

-(void)savePreferences {
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    NSMutableDictionary *userStatsDict = nil;
    NSNumber *zero = [[NSNumber alloc] initWithInt:0];
    
    if ((userStatsDict = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPStatsFile]) != nil)
    {
        [userStatsDict setObject:zero forKey:LASTLINE];
    }
    else
    {
        //NSLog(@"User stats nil");
        userStatsDict = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObject:zero] forKeys:[NSArray arrayWithObject:LASTLINE]];
    }
    
    [userStatsDict writeToFile:PureFTPStatsFile atomically:YES];
    
    NSNumber *logOnOff = [[NSNumber alloc] initWithInt:[logSwitch state]];  
    NSNumber *updateOnOff = [[NSNumber alloc] initWithInt:[updateSwitch state]]; 
    NSNumber *shareOnOff = [[NSNumber alloc] initWithInt:[shareSwitch state]]; 
    
    [preferences setObject:logOnOff forKey:PureFTPLogOnOff]; 
    [preferences setObject:updateOnOff forKey:PureFTPLogAutoUpdate]; 
    [preferences setObject:shareOnOff forKey:PureFTPLogNiceThread]; 
    
    [preferences setObject:[formatPopUp titleOfSelectedItem] forKey:PureFTPLogFormat];
    [preferences setObject:[locationField stringValue] forKey:PureFTPLogLocation];
    
    
    NSNumber *update = [[NSNumber alloc] initWithInt:1];
    [preferences setObject:update forKey:PureFTPPrefsUpdated];
    
    BOOL isDir = NO;
    if ([[NSFileManager defaultManager] fileExistsAtPath:lastLogFile isDirectory:&isDir])
    {
        if (!isDir)
            [[NSFileManager defaultManager] removeFileAtPath:lastLogFile handler:nil];
    }
    
    
    
    NSLog(@"Saving PureFTPD preferences - Logging Facilities");
    [preferences writeToFile:PureFTPPreferenceFile atomically:YES];
    
    [logOnOff release];
    [update release];
    [zero release];
    [preferences release];
    [userStatsDict release];
    modified = NO;
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
    modified = YES;
}

- (void) mainViewDidLoad {
    pureFTPPreferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    modified=NO;
    [self loadPreferences];
}

- (void) willUnselect {
    if(modified)
        [self savePreferences];    
    [pureFTPPreferences release];  
}
    
- (IBAction)chooseFile:(id)sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:YES];
    [oPanel setResolvesAliases:NO];
    NSString *activeUser = nil;
    activeUser = [[NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile] objectForKey:PureFTPActiveUser];
    
    if (activeUser != nil) {
        if ([activeUser isEqualToString:@""])
	{
            activeUser = @"root";
	}
    }
    [oPanel beginSheetForDirectory:NSHomeDirectoryForUser(activeUser) file:nil types:nil 
		    modalForWindow:[NSApp mainWindow]
		     modalDelegate: self
		    didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo: nil];
    
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
    [NSApp stopModal];
    if (returnCode == NSOKButton){
        NSString *logfile = [[sheet filenames] objectAtIndex:0];
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:logfile isDirectory:&isDir])
        {
            if (isDir)
                logfile = [logfile stringByAppendingPathComponent:@"pureftpd.log"];
        }
        
        [locationField setStringValue: logfile];
    }
    modified = YES;
}

- (IBAction)didModify:(id)sender
{
    if (sender == logSwitch)
    {
	if ([sender state] == 1)
	{
	    [formatPopUp setEnabled:YES];
	    [locationField setEnabled:YES];
	    [browseButton setEnabled:YES];
            [updateSwitch setEnabled:YES];
            [shareSwitch setEnabled:YES];
	}
	else
	{
	    [formatPopUp setEnabled:NO];
	    [locationField setEnabled:NO];
	    [browseButton setEnabled:NO];
            [updateSwitch setEnabled:NO];
            [shareSwitch setEnabled:NO];
	}
    }
    
    modified = YES;  
}

@end
