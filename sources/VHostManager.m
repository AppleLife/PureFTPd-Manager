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

#import "VHostManager.h"

// The pointer to the singleton instance
static VHostManager *theVHostManager = nil;

@implementation VHostManager

- (id)init
{
	self = [super init];
	if (self) 
        {
            preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
            if ([preferences objectForKey:PureFTPVirtualHosts] != nil)
                vhosts = [[NSMutableArray alloc] initWithArray:[preferences objectForKey:PureFTPVirtualHosts]];
            else
                vhosts = [[NSMutableArray alloc] init];
                
            modified = NO;
                
            pureController = [PureController getInstance];
        }
    return self;
}

-(void) dealloc
{
    [vhosts release];
    [pureController release];
    [preferences release];
	[super dealloc];
}

/* Get the singleton instance of this class */
+(id) getInstance
{
    	// TODO: Mutex Begin
	if (theVHostManager == nil) {
		theVHostManager = [[VHostManager alloc] init];
	}
	// TODO: Mutex End
	return theVHostManager;
}

-(void)addEmptyHost
{
    
    modified = TRUE;
    if ([vhosts count] >= 1)
        [self updateHost];
    NSMutableDictionary *newVHost = [[NSMutableDictionary alloc] init];
    [newVHost setObject:NSLocalizedString(@"New VHost", @"New VHost") forKey:@"vhost.name"];
    [newVHost setObject:@"" forKey:@"vhost.ip"];
    [newVHost setObject:@"en0" forKey:@"vhost.nic"];
    [newVHost setObject:[[NSMutableDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile] objectForKey:PureFTPVHostBaseDir] forKey:@"vhost.dir"];

    [vhosts addObject:newVHost];
    [newVHost release];
    [[pureController vhostTable] reloadData];
    
    [[pureController vhostTable] selectRow:[vhosts count]-1 byExtendingSelection:NO];
    [pureController getHostInfoFor:[vhosts objectAtIndex:[vhosts count]-1]];
}

-(void)deleteHost
{
	if (NSRunCriticalAlertPanel(NSLocalizedString(@"You are about to delete a Virtual Host.", @"You are about to delete a Virtual Host."),
		NSLocalizedString(@"Are you sure you want to continue ?",@"Are you sure you want to continue ?"),
		NSLocalizedString(@"Yes",@"Yes"),NSLocalizedString(@"No",@"No"),nil) != NSOKButton)
		return;
	
    modified = TRUE;
    NSFileManager *fm = [NSFileManager defaultManager];
    int index = [[pureController vhostTable] selectedRow];
    NSMutableDictionary *vhostInfo = [NSMutableDictionary dictionaryWithDictionary:[vhosts objectAtIndex:index]];
    
    NSMutableArray *ifargs = [NSMutableArray arrayWithObjects:[vhostInfo objectForKey:@"vhost.nic"], 
                                                                  @"-alias", [vhostInfo objectForKey:@"vhost.ip"],
                                                                  nil ]; 
    NSTask *ifconfig =[[NSTask alloc] init];
    [ifconfig setLaunchPath:@"/sbin/ifconfig"];	
    [ifconfig setArguments:ifargs];
    [ifconfig launch]; // alias removed
    [ifconfig release];
    NSString *fileToDelete = [NSString stringWithFormat:@"%@/%@", PureFTPConfDir, [vhostInfo objectForKey:@"vhost.ip"]];
    NSDictionary *fattr = [fm fileAttributesAtPath:fileToDelete traverseLink:NO];
    if ([[fattr fileType] isEqualToString:NSFileTypeSymbolicLink])
        [fm removeFileAtPath:fileToDelete handler:nil]; //link removed
    
    
    [vhosts removeObjectAtIndex:index];
    [[pureController vhostTable] reloadData];
    
    int newIndex = [[pureController vhostTable] selectedRow];
    if (newIndex != -1)
    {
        [pureController getHostInfoFor:[vhosts objectAtIndex:newIndex]];
    }
    else 
        [pureController clearHostFields];
    [self savetoPreferences];
}

-(void) updateHost
{
    NSMutableDictionary *dict = [vhosts objectAtIndex:[[pureController vhostTable] selectedRow]];
    if (![[dict objectForKey:@"vhost.name"] isEqualToString:[[pureController vhostNameField] stringValue]])
        [dict setObject:[[pureController vhostNameField] stringValue] forKey:@"vhost.name"];
    if (![[dict objectForKey:@"vhost.ip"] isEqualToString:[[pureController vhostIPField] stringValue]])
        [dict setObject:[[pureController vhostIPField] stringValue] forKey:@"vhost.ip"];
    if (![[dict objectForKey:@"vhost.nic"] isEqualToString:[[pureController vhostNICPopUp] titleOfSelectedItem]])
        [dict setObject:[[pureController vhostNICPopUp] titleOfSelectedItem] forKey:@"vhost.nic"];
    if (![[dict objectForKey:@"vhost.dir"] isEqualToString:[[pureController vhostDirField] stringValue]])
        [dict setObject:[[pureController vhostDirField] stringValue] forKey:@"vhost.dir"];
}

-(NSMutableArray *)vhosts
{
    return vhosts;
}

-(void) saveAlert
{

    NSBeginAlertSheet(NSLocalizedString(@"Virtual Hosts have been modified",@"localized string"), 
                      NSLocalizedString(@"Save",@"Save"), 
                      NSLocalizedString(@"Cancel",@"Cancel"),
                      NSLocalizedString(@"Don't Save",@"Don't Save"),
                      [NSApp mainWindow], self, @selector(sheetDidEnd:returnCode:contextInfo:), 
                      NULL, NULL, NSLocalizedString(@"Would you like to apply these changes to PureFTPd ?",@"localized string"),
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
    if (returnCode == NSAlertDefaultReturn)
    {
        [self savetoPreferences];
        [pureController setSelectNow:YES];
        [NSApp stopModal];
    }
    else if (returnCode == NSAlertOtherReturn)
    {
        [vhosts release];
        if ([preferences objectForKey:PureFTPVirtualHosts] != nil)
                vhosts = [[NSMutableArray alloc] initWithArray:[preferences objectForKey:PureFTPVirtualHosts]];
            else
                vhosts = [[NSMutableArray alloc] init];
        
        [pureController setSelectNow:YES];
        modified=FALSE;
        
        
        [[pureController vhostTable] reloadData];
        [NSApp stopModal];
        if ([[pureController vhostTable] selectedRow] != -1)
            [pureController getHostInfoFor:[vhosts objectAtIndex:0]];
    }
    else if (returnCode == NSAlertAlternateReturn)
    {
        [pureController setSelectNow:NO];
        [NSApp stopModal];
    }
    
}

-(void)savetoPreferences
{
    if ([vhosts count]>= 1)
        [self updateHost];
    [preferences setObject:vhosts forKey:PureFTPVirtualHosts];
    [preferences writeToFile:PureFTPPreferenceFile atomically:YES];
    modified = FALSE;
    [self setupVHosts];
    
    [[pureController vhostTable] reloadData];
}

-(BOOL)areVhostsModified
{
    return modified;
}

-(void)setModified:(BOOL)flag
{
    modified = flag;
}

-(void) setupVHosts
{
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSEnumerator *vhostEnum = [vhosts objectEnumerator];
    NSMutableDictionary *vhostInfo;
    

    while (vhostInfo = [vhostEnum nextObject]){
        NSMutableArray *ifargs = [NSMutableArray arrayWithObjects:[vhostInfo objectForKey:@"vhost.nic"], 
                                                                  @"alias", [vhostInfo objectForKey:@"vhost.ip"],
                                                                  nil ]; 
        //NSLog(@"%@", [ifargs description]);
        NSTask *ifconfig =[[NSTask alloc] init];
        [ifconfig setLaunchPath:@"/sbin/ifconfig"];	
        [ifconfig setArguments:ifargs];
        [ifconfig launch]; 
        [ifconfig release]; // alias created
        NSString *linkPath = [NSString stringWithFormat:@"%@/%@", PureFTPConfDir, [vhostInfo objectForKey:@"vhost.ip"]]; 
        [fm createSymbolicLinkAtPath:linkPath pathContent:[vhostInfo objectForKey:@"vhost.dir"]]; //link created
    }
    
}

// vhostTable DataSource
- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
    if ([vhosts count] == 0)
        [pureController disableHostFields];
    else
        [pureController enableHostFields];
    return [vhosts count];
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn *)col row:(int)row
{
    return [[vhosts objectAtIndex:row] objectForKey:[col identifier]];
}

// vhostTable delegates
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    [self updateHost];
        
    NSMutableDictionary *tmpDict = [NSMutableDictionary dictionaryWithDictionary:[vhosts objectAtIndex:row]];
    [pureController getHostInfoFor:tmpDict];
    return YES;
}

@end
