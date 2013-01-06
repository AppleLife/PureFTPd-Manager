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

#import "AKSystemPaneController.h"
#import "ManagerProcessEngine.h"

@implementation AKSystemPaneController

- (BOOL) checkPaneValuesWithEngine:(id) inEngine
{
    NSMutableDictionary *myOptions = [inEngine wizardOptions];
    
    
    [myOptions setObject:[NSNumber numberWithInt:[startupSwitch state]]
                  forKey:ATSTARTUP];
	[myOptions setObject:[NSNumber numberWithInt:[pamSwitch state]]
                  forKey:@"ALLOWPAM"];
    [myOptions setObject:[vhostBaseDirField stringValue] 
                  forKey:VHHOME];
    [myOptions setObject:[vuserBaseDirField stringValue] 
                  forKey:VUHOME];
    
    return YES;
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
                       contextInfo: (void *)[sender tag]];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
    [NSApp stopModal];
    if (returnCode == NSOKButton && ((int)contextInfo==200)){
        [vuserBaseDirField setStringValue: [[sheet filenames] objectAtIndex:0]];
    }
    else if (returnCode == NSOKButton && ((int)contextInfo==300))
        [vhostBaseDirField setStringValue: [[sheet filenames] objectAtIndex:0]];
}

@end
