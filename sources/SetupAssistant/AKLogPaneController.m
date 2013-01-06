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

#import "AKLogPaneController.h"
#import "ManagerProcessEngine.h"

@implementation AKLogPaneController


- (IBAction)toggleOthers:(id)sender
{
    if ([sender state] == NSOffState)
    {
        [prioritySwitch setEnabled:NO];
        [prioritySwitch setState:0];
        [updateSwitch setEnabled:NO];
        [updateSwitch setState:0];
        
    }
    else 
    {
        [prioritySwitch setEnabled:YES];
        [prioritySwitch setState:1];
        [updateSwitch setEnabled:YES];
    }
}

- (BOOL) checkPaneValuesWithEngine:(id) inEngine
{
    NSMutableDictionary *myOptions = [inEngine wizardOptions];
    
    
    [myOptions setObject:[NSNumber numberWithInt:[prioritySwitch state]]
                  forKey: LOGNICE];
    [myOptions setObject:[NSNumber numberWithInt:[logSwitch state]]
                  forKey:LOGSTATE];
    [myOptions setObject:[NSNumber numberWithInt:[updateSwitch state]] 
                  forKey:LOGUPDATE];
    
    return YES;
}

@end
