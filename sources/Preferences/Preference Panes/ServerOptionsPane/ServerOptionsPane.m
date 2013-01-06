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

#import "ServerOptionsPane.h"
#import "defines.h"

@implementation ServerOptionsPane
- (id) initWithBundle:(NSBundle *) bundle {
    self = [super initWithBundle:bundle] ;
    
    return self ;
}

- (void) dealloc {
    [super dealloc];
}

-(void) loadPreferences{
    [noResolveSwitch setState:[[pureFTPPreferences objectForKey:PureFTPResolvName] intValue]];
    [activeModeSwitch setState:[[pureFTPPreferences objectForKey:PureFTPForceActive] intValue]];
    [ipForcedField setStringValue:[pureFTPPreferences objectForKey:PureFTPForceIP]];
    [partitionField setStringValue:[pureFTPPreferences objectForKey:PureFTPMaxPartition]];
    
    // SpeedLimits
    if (!([[pureFTPPreferences objectForKey:PureFTPUserSpeedLimit] isEqualToString:@""]))
    {
        NSArray *speed = [NSArray arrayWithArray:[[pureFTPPreferences objectForKey:PureFTPUserSpeedLimit] componentsSeparatedByString:@":"]];
        int upbw = [[speed objectAtIndex:0] intValue];
	int downbw = [[speed objectAtIndex:1] intValue];
	
	if(upbw != 0)
	    [upBWField setStringValue:[NSString stringWithFormat:@"%d", upbw]];
	else
	    [upBWField setStringValue:@""];
	
	if(downbw != 0)
	    [downBWField setStringValue:[NSString stringWithFormat:@"%d", downbw]];
	else
	    [downBWField setStringValue:@""];
	}
	
	// recursion limits PureFTPRecursionLimit
	NSString *rlimit = [pureFTPPreferences objectForKey:PureFTPRecursionLimit]; 
	if ((rlimit !=nil) && ([rlimit length] > 0))
	{
		NSArray *fd = [NSArray arrayWithArray:[rlimit componentsSeparatedByString:@":"]];
		[maxFilesField setStringValue:[fd objectAtIndex:0]];
		[maxDepthField setStringValue:[fd objectAtIndex:1]];
	}
    
    [extraArgField setStringValue:[pureFTPPreferences objectForKey:PureFTPExtraArguments]];
}


-(void) savePreferences{
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
     
    NSNumber *resolvOption = [[NSNumber alloc] initWithInt:[noResolveSwitch state]];
    NSNumber *activeMode = [[NSNumber alloc] initWithInt:[activeModeSwitch state]];
    
    // Get User Speed Limit
    NSString *speedLimit;
    if ([[upBWField stringValue] isEqualTo:@""] ||
        [[downBWField stringValue] isEqualTo:@""] )
        speedLimit=@"";
    else
        speedLimit=[NSString stringWithFormat:@"%d:%d", [upBWField intValue], [downBWField intValue]]; 
    
	// get recursion limit
	NSString *maxFiles = @"2000";
	NSString *maxDepth = @"5";
	if (![[maxFilesField stringValue] isEqualToString:@""])
		maxFiles = [maxFilesField stringValue];
	if (![[maxDepthField stringValue] isEqualToString:@""])
		maxDepth = [maxDepthField stringValue];
	NSString *rl = [NSString stringWithFormat:@"%@:%@", maxFiles, maxDepth];
	
    [preferences setObject:resolvOption forKey:PureFTPResolvName];
    [preferences setObject:activeMode forKey:PureFTPForceActive];
    [preferences setObject:[ipForcedField stringValue] forKey:PureFTPForceIP];
    [preferences setObject:[partitionField stringValue] forKey:PureFTPMaxPartition];
    [preferences setObject:speedLimit forKey:PureFTPUserSpeedLimit];
	[preferences setObject:rl forKey:PureFTPRecursionLimit];
    [preferences setObject:[extraArgField stringValue] forKey:PureFTPExtraArguments];
                
    NSNumber *update = [[NSNumber alloc] initWithInt:1];
    [preferences setObject:update forKey:PureFTPPrefsUpdated];
    
    //NSLog(@"Saving PureFTPD preferences - Server Options");
    [preferences writeToFile:PureFTPPreferenceFile atomically:YES];
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

