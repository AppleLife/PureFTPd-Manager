
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

#import "PermissionPane.h"
#import "defines.h"

@implementation PermissionPane
- (id) initWithBundle:(NSBundle *) bundle {
    self = [super initWithBundle:bundle] ;
    
    return self ;
}

#pragma mark Preference Pane view delegates
- (void) mainViewDidLoad {
    [self loadPreferences];
    modified=NO;
}


- (void) willUnselect {
    if(modified) {
        [self savePreferences];    
    }   
}


#pragma mark Load / Save preferences

-(void) loadPreferences{
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    // check the radio button
    [checkVFolderButton setState:[[preferences objectForKey:PureFTPCheckVFolderPerm] intValue]];
    [consoleButton setState:[[preferences objectForKey:PureFTPShowVFolderConsole] intValue]];
	NSString *fileMask = nil;
	NSString *folderMask = nil;
	fileMask = [preferences objectForKey:PureFTPFileCreationMask];
	if (fileMask == nil)
		fileMask =@"133";
	
	folderMask = [preferences objectForKey:PureFTPFolderCreationMask];
	if (folderMask == nil)
		folderMask = @"022";
	
	[self setFileRepresentationForMask:fileMask];
	[self setFolderRepresentationForMask:folderMask];
	
    [preferences release];
}

-(void) savePreferences{
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    
    NSNumber *checkState = [[NSNumber alloc] initWithInt:[checkVFolderButton state]]; 
    [preferences setObject:checkState forKey:PureFTPCheckVFolderPerm]; 
    [checkState release];
    NSNumber *consoleState = [[NSNumber alloc] initWithInt:[consoleButton state]]; 
    [preferences setObject:consoleState forKey:PureFTPShowVFolderConsole]; 
    [consoleState release];
    
	// save umask values
	[preferences setObject:[umaskFileField stringValue] forKey:PureFTPFileCreationMask];
	[preferences setObject:[umaskFolderField stringValue] forKey:PureFTPFolderCreationMask];
	
	NSNumber *update = [[NSNumber alloc] initWithInt:1];
    [preferences setObject:update forKey:PureFTPPrefsUpdated];
    
    NSLog(@"Saving PureFTPD preferences - Permissions Pane");
    [preferences writeToFile:PureFTPPreferenceFile atomically:YES];

    [preferences release];
    //[update release];
    modified = NO;
}

- (IBAction)didModify:(id)sender
{
    modified=YES;
}

- (IBAction)fileMaskChanged:(id)sender
{
	NSString *user = [NSString stringWithFormat:@"%d", [userFilePopUp indexOfSelectedItem]];
	NSString *group = [NSString stringWithFormat:@"%d", [groupFilePopUp indexOfSelectedItem]];
	NSString *other = [NSString stringWithFormat:@"%d", [otherFilePopUp indexOfSelectedItem]]; 
	NSString *umask = [NSString stringWithFormat:@"%@%@%@", user, group, other];
	
	[umaskFileField setStringValue:umask];
	
	modified=YES;
}

- (IBAction)folderMaskChanged:(id)sender
{
	NSString *user = [NSString stringWithFormat:@"%d", [userFolderPopUp indexOfSelectedItem]];
	NSString *group = [NSString stringWithFormat:@"%d", [groupFolderPopUp indexOfSelectedItem]];
	NSString *other = [NSString stringWithFormat:@"%d", [otherFolderPopUp indexOfSelectedItem]]; 
	NSString *umask = [NSString stringWithFormat:@"%@%@%@", user, group, other];
	
	[umaskFolderField setStringValue:umask];
	
	modified=YES;
}

- (IBAction)setDefaultMask:(id)sender
{
	[self setFileRepresentationForMask:@"133"];
	[self setFolderRepresentationForMask:@"022"];
	modified=YES;
}

-(void)setFileRepresentationForMask:(NSString *)umask
{
	[umaskFileField setStringValue:umask];
	NSString *user = [NSString stringWithFormat:@"%c", [umask characterAtIndex:0]];
	NSString *group = [NSString stringWithFormat:@"%c", [umask characterAtIndex:1]];
	NSString *other = [NSString stringWithFormat:@"%c", [umask characterAtIndex:2]];
	[userFilePopUp selectItemAtIndex:[user intValue]];
	[groupFilePopUp selectItemAtIndex:[group intValue]];
	[otherFilePopUp selectItemAtIndex:[other intValue]];
}

-(void)setFolderRepresentationForMask:(NSString *)umask
{
	[umaskFolderField setStringValue:umask];
	NSString *user = [NSString stringWithFormat:@"%c", [umask characterAtIndex:0]];
	NSString *group = [NSString stringWithFormat:@"%c", [umask characterAtIndex:1]];
	NSString *other = [NSString stringWithFormat:@"%c", [umask characterAtIndex:2]];
	[userFolderPopUp selectItemAtIndex:[user intValue]];
	[groupFolderPopUp selectItemAtIndex:[group intValue]];
	[otherFolderPopUp selectItemAtIndex:[other intValue]];
}

  

@end
