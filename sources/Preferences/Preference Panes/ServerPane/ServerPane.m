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

#import "ServerPane.h"
#import "defines.h"

@implementation ServerPane
- (id) initWithBundle:(NSBundle *) bundle {
    self = [super initWithBundle:bundle] ;
    return self ;
}

- (void) dealloc {
	[super dealloc];
}

-(void) loadPreferences{
	if (![[pureFTPPreferences objectForKey:PureFTPServerMode] intValue])
	{
		[portField setEnabled:FALSE];
		[portField setStringValue:@"21"];
		/*[portField setToolTip:NSLocalizedString(
			@"Your FTP server currently runs using Mac OS X Superserver.\n\
In order to use another port, you need to run pure-ftpd in standalone mode.\n\
To do this, go to PureFTPd Manager's \"Mac OS X\" preference pane and choose \"Use Standalone mode\".",
			@"Your FTP server currently runs using Mac OS X Superserver.\n\
In order to use another port, you need to run pure-ftpd in standalone mode.\n\
To do this, go to PureFTPd Manager's \"Mac OS X\" preference pane and choose \"Use Standalone mode\".")];*/
	} else {
		[portField setEnabled:TRUE];
		[portField setStringValue:[pureFTPPreferences objectForKey:PureFTPPort]];
		[portField setToolTip:nil];
	}
    // Passive range
    if (!([[pureFTPPreferences objectForKey:PureFTPPassiveRange] isEqualToString:@""]))
    {
        NSArray *range = [NSArray arrayWithArray:[[pureFTPPreferences objectForKey:PureFTPPassiveRange] componentsSeparatedByString:@":"]];
        [passiveRangeFromField setStringValue:[range objectAtIndex:0]];
        [passiveRangeToField setStringValue:[range objectAtIndex:1]];
    }
    
	
	
    [maxUsersField setStringValue:[pureFTPPreferences objectForKey:PureFTPMaxUsers]];
    [timeoutField setStringValue:[pureFTPPreferences objectForKey:PureFTPTimeout]];
    [maxSessionsField setStringValue:[pureFTPPreferences objectForKey:PureFTPMaxSessions]];
    [fxpPopUpButton selectItemAtIndex:[[pureFTPPreferences objectForKey:PureFTPFXP] intValue]];    
}

-(void) savePreferences{
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    
    // Check default options
    // Port
    NSString *port;
    if ([[portField stringValue] isEqualToString:@""])
        port=@"21";
    else
        port = [NSString stringWithString:[portField stringValue]];
        
    // Timeout
    NSString *timeout;
    if ([[timeoutField stringValue] isEqualToString:@""])
        timeout=@"15";
    else
        timeout = [NSString stringWithString:[timeoutField stringValue]];
    
    // Max users
    NSString *maxUsers;
    if ([[timeoutField stringValue] isEqualToString:@""])
        maxUsers=@"50";
    else
        maxUsers = [NSString stringWithString:[maxUsersField stringValue]];
    
    // Get Passive Range
    NSString *passiveRange;
    if ([[passiveRangeFromField stringValue] isEqualTo:@""] ||
        [[passiveRangeToField stringValue] isEqualTo:@""] )
        passiveRange=@"";
    else
        passiveRange=[NSString stringWithFormat:@"%@:%@", [passiveRangeFromField stringValue], [passiveRangeToField stringValue]];
    
    // Get FXP 
    // 0 : FXPDisabled
    // 1 : FXPEveryone
    // 2 : FXPAuthOnly
    NSNumber *fxp = [[NSNumber alloc] initWithInt:[[fxpPopUpButton selectedItem] tag]];
    
    
    [preferences setObject:port forKey:PureFTPPort];
    [preferences setObject:timeout forKey:PureFTPTimeout];
    [preferences setObject:passiveRange forKey:PureFTPPassiveRange];
    [preferences setObject:fxp forKey:PureFTPFXP];
    [preferences setObject:maxUsers forKey:PureFTPMaxUsers];
    [preferences setObject:[maxSessionsField stringValue] forKey:PureFTPMaxSessions];

    NSNumber *update = [[NSNumber alloc] initWithInt:1];
    [preferences setObject:update forKey:PureFTPPrefsUpdated];
    
    //NSLog(@"Saving PureFTPD preferences - Server Settings Pane");
    [preferences writeToFile:PureFTPPreferenceFile atomically:YES];
    
    [fxp release];
    [preferences release];
    
    modified = NO;
}

// Delegates
// TextFields
- (void)controlTextDidChange:(NSNotification *)aNotification
{
    modified = YES;
}

- (IBAction)didModify:(id)sender
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



@end

