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

#import "StatusController.h"
#import "PureController.h"
#import "MVPreferencesController.h" 
#import "RemoveController.h"

@implementation StatusController

#pragma mark Initialization
StatusController *theStatusController = nil;

/* Get the singleton instance of this class */
+(id) getInstance
{
    // TODO: Mutex Begin
    if (theStatusController == nil) {
        theStatusController = [[StatusController alloc] init];
    }
    // TODO: Mutex End
    return theStatusController;
}


-(id) init 
{
    self = [super init];
    if (self)
    {
        theStatusController = self;
        // Listening to refresh notifications
        [[NSDistributedNotificationCenter defaultCenter] addObserver:self
                                                            selector:@selector(refreshStatus:)
                                                                name:@"refreshStatus" object:nil];
        
    }
    return self;
}


- (void)awakeFromNib
{
    
    theStatusController = self;
    
    pureFTPD = [[PureFTPD alloc] init];
    myUsage = [[FTPUsage alloc] init];
    statusDictionary = [[NSMutableDictionary alloc] init];

        
    [progress setStyle:NSProgressIndicatorSpinningStyle];
    [progress setDisplayedWhenStopped:NO];

    // Refresh the status    
    [self refreshStatus:nil];
    
    NSMutableDictionary *prefs=nil;
    prefs = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
    if([[prefs objectForKey:@"PureFTPAutoUpdateStatus"] intValue])
    {
        [autoUpdateSwitch setState:NSOnState];
        autoUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(refreshStatus:)  userInfo:nil repeats:YES] retain];
    }
    
    NSString *managerImagePath = [NSBundle pathForResource:@"Manager" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *assistantPath = [NSBundle pathForResource:@"assistant" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *trashPath = [NSBundle pathForResource:@"trash" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *statusPath = [NSBundle pathForResource:@"status" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *loggingPath = [NSBundle pathForResource:@"logging" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *usersPath = [NSBundle pathForResource:@"users" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *vhostsPath = [NSBundle pathForResource:@"vhosts" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *systemPath = [NSBundle pathForResource:@"system" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *settingsPath = [NSBundle pathForResource:@"settings" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *anonymousPath = [NSBundle pathForResource:@"anonymous" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *authPath = [NSBundle pathForResource:@"auth" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *sslPath = [NSBundle pathForResource:@"ssl" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *diraliasesPath = [NSBundle pathForResource:@"diraliases" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *optionsPath = [NSBundle pathForResource:@"options" ofType:@"png" inDirectory:[[NSBundle mainBundle] bundlePath]];
	
	NSString *mainHTML = [NSBundle pathForResource:@"main" ofType:@"html" inDirectory:[[NSBundle mainBundle] bundlePath]];
    NSString *formattedPage = [NSString stringWithFormat:[NSString stringWithContentsOfFile:mainHTML], managerImagePath, assistantPath, trashPath, statusPath, loggingPath, usersPath, vhostsPath, systemPath, settingsPath, anonymousPath, authPath, sslPath, diraliasesPath, optionsPath];
    
    [[statusWV mainFrame] loadHTMLString:formattedPage baseURL:nil];
}


#pragma mark Deallocation
- (void)dealloc
{
    // Stop listening for notifications
    [[NSDistributedNotificationCenter defaultCenter] removeObserver:self 
                                                               name:@"refreshStatus" 
                                                             object:nil];
    
    [pureFTPD release];
    [myUsage release];
    [statusDictionary release];
    if (sortedArray)
        [sortedArray release];
    [super dealloc];
}

#pragma mark Refresh status
- (void)updateUserStatus
{
    if ([statusDictionary count] > 0)
        [statusDictionary removeAllObjects];
    
    [myUsage update];
    
    NSMutableDictionary *userInfo;
    NSEnumerator *enumerator = [[myUsage usersDB] objectEnumerator];
    
    NSMutableArray *userInfoArray = nil;
    while(userInfo = [enumerator nextObject])
    {
        NSString *key = [userInfo objectForKey:@"account"];
        if ((userInfoArray=[statusDictionary objectForKey:key]) == nil){
            // User was not found
            userInfoArray = [NSMutableArray arrayWithObject:userInfo];
			if (userInfoArray != nil)
				[statusDictionary setObject:userInfoArray forKey:key];
        } else {
            // User was found
            [userInfoArray addObject:userInfo];
        }
    }
    
    NSMutableArray *keyArray = [NSArray arrayWithArray:[statusDictionary allKeys]];
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
        sortedArray=[[NSMutableArray alloc] initWithArray:[usersArray sortedArrayUsingDescriptors:sortDescriptors]];
    } else {
        if (sortedArray)
            [sortedArray release];
        sortedArray = [[NSMutableArray alloc] initWithArray:usersArray];
    }
    
    [usersArray release];
}

- (void)updateServerStatus
{
    int bwUsage = 0;
    int session = 0;
    id userArray;
    NSEnumerator *bwenum = [statusDictionary objectEnumerator];
    while (userArray = [bwenum nextObject])
    {
        session+=[userArray count];
        id sessionInfo;
        NSEnumerator *userEnum = [userArray objectEnumerator];
        while (sessionInfo = [userEnum nextObject]){
            bwUsage+=[[sessionInfo objectForKey:@"bandwidth"] intValue];
        }
    }
    
    NSNumber *size = [self formatSize:[NSNumber numberWithInt:bwUsage] forCell:[totalBWUsageField cell]];
    NSString *sessions = [NSString stringWithFormat:@"%d", session];
    [totalBWUsageField setStringValue:[size stringValue]];
    [sessionInfoField setStringValue:sessions];

    
    if ([pureFTPD isServerRunning])
    {
        [controlServerBtn setTitle:NSLocalizedString(@"Stop",@"Stop")];
        [serverStatusField setStringValue:NSLocalizedString(@"pure-ftpd is running ...",@"pure-ftpd is running ...")];
    }
    else
    {
        [controlServerBtn setTitle:NSLocalizedString(@"Start",@"Start")];
        [serverStatusField setStringValue:NSLocalizedString(@"pure-ftpd is not running !",@"pure-ftpd is not running !")];
    }
    [fileField setStringValue:@""];
    [localHostField setStringValue:@""];
    [localPortField setStringValue:@""];
    [pidField setStringValue:@""];
    [resumeField setStringValue:@""];
    [sizeField setStringValue:@""];
}


- (void)refreshStatus:(NSNotification *)notification
{
    
    [self updateUserStatus];
    [self updateServerStatus];
	int selectedUserDetailRow = [userDetailTable selectedRow];
    [userTable reloadData];
    [userDetailTable reloadData];
	
	if(selectedUserDetailRow !=-1)
	{
		//[userDetailTable selectRow:selectedUserDetailRow byExtendingSelection:NO];
		NSArray *userArray= [statusDictionary objectForKey:[[sortedArray objectAtIndex:[userTable selectedRow]] objectForKey:@"account"]];
        NSDictionary *userRecord = [userArray objectAtIndex:selectedUserDetailRow];
        
        NSNumber *size = [self formatSize:[NSNumber numberWithInt:[[userRecord objectForKey:@"current_size"] intValue]] forCell:[sizeField cell]];
        
        //[userRecord objectForKey:@"tc_filename"];
        [fileField setStringValue:[userRecord objectForKey:@"file"]];
        [localHostField setStringValue:[userRecord objectForKey:@"localhost"]];
        [localPortField setStringValue:[userRecord objectForKey:@"localport"]];
        [pidField setStringValue:[userRecord objectForKey:@"pid"]];
        [resumeField setStringValue:[userRecord objectForKey:@"resume"]];
        [sizeField setStringValue:[size stringValue]];
	}
    
    [progress stopAnimation:nil];
}

#pragma mark Close sessions Actions
- (IBAction)closeAllSessions:(id)sender
{

    int index = [userTable selectedRow];
    //NSMutableArray *keyArray = [NSMutableArray arrayWithArray:[statusDictionary allKeys]];
    NSArray  *userArray = [statusDictionary objectForKey:[[sortedArray objectAtIndex:index] objectForKey:@"account"]];

    id dict;
    NSEnumerator *infoEnum = [userArray objectEnumerator];
    while (dict=[infoEnum nextObject])
    {
        int userPID = [[dict objectForKey:@"pid"] intValue];
        kill(userPID, SIGTERM);
    }
    
    [userTable deselectRow:index];
    
    [statusDictionary removeObjectForKey:[[sortedArray objectAtIndex:index] objectForKey:@"account"]];
    [sortedArray removeObjectAtIndex:index];
    
    [userDetailTable reloadData];
    [userTable reloadData];
    
    [self updateServerStatus];
}

- (IBAction)closeSession:(id)sender
{
     int index = [userTable selectedRow];
   // NSMutableArray *keyArray = [NSMutableArray arrayWithArray:[statusDictionary allKeys]];
    NSMutableArray  *userArray = [NSMutableArray arrayWithArray:[statusDictionary objectForKey:[[sortedArray objectAtIndex:index] objectForKey:@"account"]]];
    NSMutableDictionary *userRecord = [userArray objectAtIndex:[userDetailTable selectedRow]];
    
    int userPID = [[userRecord objectForKey:@"pid"] intValue];
    kill(userPID, SIGTERM);
    
    [userArray removeObjectAtIndex:[userDetailTable selectedRow]];
    [statusDictionary setObject:userArray forKey:[[sortedArray objectAtIndex:index] objectForKey:@"account"]];
    if ([userArray count] < 1){
        [statusDictionary removeObjectForKey:[[sortedArray objectAtIndex:index] objectForKey:@"account"]];
        [userTable reloadData];
        [userDetailTable reloadData];
    } else {
        [userDetailTable reloadData];
    }
    
    [self updateServerStatus];
}


#pragma mark Control Server Actions

-(void) startServer:(id)sender
{
    [progress startAnimation:self];    
    [pureFTPD startServer];
    [self performSelector:@selector(refreshStatus:) withObject:nil afterDelay:3.0];
}

-(void) stopServer:(id)sender
{
    [progress startAnimation:self];
    [pureFTPD stopServer];
    
    int pid;
    id userArray;
    NSEnumerator *bwenum = [statusDictionary objectEnumerator];
    while (userArray = [bwenum nextObject])
    {   
        id sessionInfo;
        NSEnumerator *userEnum = [userArray objectEnumerator];
        while (sessionInfo = [userEnum nextObject]){
            pid=[[sessionInfo objectForKey:@"pid"] intValue];
            kill(pid, SIGTERM);
        }
    }
    
    [self performSelector:@selector(refreshStatus:) withObject:nil afterDelay:3.0];
    
}

- (IBAction)controlServer:(id)sender
{
    if ([pureFTPD isServerRunning])
    {
        [self stopServer:nil];
    }
    else // start the server
    {
        [self startServer:nil];
    }
    
}

#pragma mark Utility functions
-(NSNumber *)formatSize:(NSNumber *)number forCell:(id)cell
{
    int koctet = 1024;
    int moctet = koctet*1024;
    int goctet = moctet * 1024;
    
    NSNumberFormatter *numberFormat = [[[NSNumberFormatter alloc] init] autorelease];
    if ([number intValue] < 1024){
        [numberFormat setFormat:@"#,##0 B"];
        [cell setFormatter:numberFormat];
        return number;
    }    
    else if (([number intValue] >= 1024) && ([number intValue] < moctet))
    {
        [numberFormat setFormat:@"#,##0 KB"];
        [cell setFormatter:numberFormat];
        return [NSNumber numberWithInt:[number intValue]/koctet];
    }
    else if (([number intValue] >= moctet) && ([number intValue] < goctet))
    {
        [numberFormat setFormat:@"#,##0 MB"];
        [cell setFormatter:numberFormat];
        return [NSNumber numberWithInt:[number intValue]/moctet];
    }
    else if ([number intValue] >= goctet)
    {
        [numberFormat setFormat:@"#,##0 GB"];
        [cell setFormatter:numberFormat];
        return [NSNumber numberWithInt:[number intValue]/goctet];
    }
    
    return nil;
}



- (IBAction)toggleAutoUpdate:(id)sender
{
    NSMutableDictionary *prefs=nil;
    prefs = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];

    switch ([sender state]){
        case NSOnState:
            [self refreshStatus:nil];
            if (autoUpdateTimer){
                [autoUpdateTimer invalidate];
                [autoUpdateTimer release];
                autoUpdateTimer = nil;
            }
            autoUpdateTimer = [[NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(refreshStatus:)  userInfo:nil repeats:YES] retain];
            [prefs setObject:@"1" forKey:@"PureFTPAutoUpdateStatus"];
            [prefs writeToFile:PureFTPPreferenceFile atomically:YES];
            break;
        case NSOffState:
            if (autoUpdateTimer){
                [autoUpdateTimer invalidate];
                [autoUpdateTimer release];
                autoUpdateTimer = nil;
            }
            [prefs setObject:@"0" forKey:@"PureFTPAutoUpdateStatus"];
            [prefs writeToFile:PureFTPPreferenceFile atomically:YES];
            break;
    }
}


#pragma mark Tableviews delegate functions

- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    if ([tableView isEqualTo:userTable])  {
        [fileField setStringValue:@""];
        [localHostField setStringValue:@""];
        [localPortField setStringValue:@""];
        [pidField setStringValue:@""];
        [resumeField setStringValue:@""];
        [sizeField setStringValue:@""];
        if (row == -1){
            [closeAllSessionsBtn setEnabled:NO];
        } else {
            [closeAllSessionsBtn setEnabled:YES];
        }
            
    }
    else if ([tableView isEqualTo:userDetailTable])
    {
        
        //NSMutableArray *keyArray = [NSMutableArray arrayWithArray:[statusDictionary allKeys]];
        
        NSArray *userArray= [statusDictionary objectForKey:[[sortedArray objectAtIndex:[userTable selectedRow]] objectForKey:@"account"]];
        NSMutableDictionary *userRecord = [userArray objectAtIndex:row];
        
        NSNumber *size = [self formatSize:[NSNumber numberWithInt:[[userRecord objectForKey:@"current_size"] intValue]] forCell:[sizeField cell]];
        
        //[userRecord objectForKey:@"tc_filename"];
        [fileField setStringValue:[userRecord objectForKey:@"file"]];
        [localHostField setStringValue:[userRecord objectForKey:@"localhost"]];
        [localPortField setStringValue:[userRecord objectForKey:@"localport"]];
        [pidField setStringValue:[userRecord objectForKey:@"pid"]];
        [resumeField setStringValue:[userRecord objectForKey:@"resume"]];
        [sizeField setStringValue:[size stringValue]];
        
        if (row == -1){
            [closeOneSessionBtn setEnabled:NO];
        } else {
            [closeOneSessionBtn setEnabled:YES];
        }        
    }
    return YES;
}

- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    if ([[aNotification object] isEqualTo:userTable] && ([userTable selectedRow] != -1))    
    {
        
        [fileField setStringValue:@""];
        [localHostField setStringValue:@""];
        [localPortField setStringValue:@""];
        [pidField setStringValue:@""];
        [resumeField setStringValue:@""];
        [sizeField setStringValue:@""];
        [userDetailTable reloadData];
    }
    
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    if ([[aNotification object] isEqualTo:userDetailTable]){
        if ([userDetailTable selectedRow] == -1){
            [fileField setStringValue:@""];
            [localHostField setStringValue:@""];
            [localPortField setStringValue:@""];
            [pidField setStringValue:@""];
            [resumeField setStringValue:@""];
            [sizeField setStringValue:@""];
            [closeOneSessionBtn setEnabled:NO];
        }     
    } else if ([[aNotification object] isEqualTo:userTable]){
         if ([userTable selectedRow] == -1){
             [userTab selectTabViewItemAtIndex:0];
             [closeAllSessionsBtn setEnabled:NO];
         } else {
             [userTab selectTabViewItemAtIndex:1];
        }
        [userDetailTable deselectAll:nil];
    }
}



#pragma mark Tableviews datasource functions
- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
    //NSMutableArray *keyArray = [NSMutableArray arrayWithArray:[statusDictionary allKeys]];
    
    if([tableView isEqualTo:userTable]){
        int count = [sortedArray count];
        return count;
    } else if ([tableView isEqualTo:userDetailTable]) {
        if ([userTable selectedRow]!=-1) {
            int count = [[statusDictionary objectForKey:[[sortedArray objectAtIndex:[userTable selectedRow]] objectForKey:@"account"]] count];
            return count;
        } else {
            return 0;
        }
    }
    
    // We should never reach this
    return 0;
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn *)col row:(int)row
{
    //NSMutableArray *keyArray = [NSMutableArray arrayWithArray:[statusDictionary allKeys]];
    NSArray *userArray;
    NSMutableDictionary *userRecord;
    
    if([tableView isEqualTo:userTable]){
        return [[sortedArray objectAtIndex:row] objectForKey:@"account"];
    } else if ([tableView isEqualTo:userDetailTable] && ([userTable selectedRow] != -1)) {
        userArray = [statusDictionary objectForKey:[[sortedArray objectAtIndex:[userTable selectedRow]] objectForKey:@"account"]];
        userRecord = [userArray objectAtIndex:row];
        if([col isEqualTo:tc_bandwidth])
        {
            return [self formatSize:[NSNumber numberWithInt:[[userRecord objectForKey:[col identifier]] intValue]] forCell:[tc_bandwidth dataCell]];
        } else {
            return [userRecord objectForKey:[col identifier]];
        }
    }
    
    
    return nil;
}


#pragma mark -
#pragma mark WebPolicy delegate
- (void)webView:(WebView *)sender decidePolicyForNavigationAction:(NSDictionary *)actionInformation 
        request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id<WebPolicyDecisionListener>)listener
{       
    int key = [[actionInformation objectForKey: WebActionNavigationTypeKey] intValue];
    NSURL *clickURL = nil;
    PureController *controller = [PureController getInstance];
    MVPreferencesController *preferences = [[MVPreferencesController sharedInstance] retain];
    RemoveController *rc = [RemoveController getInstance];
    switch(key){
        case WebNavigationTypeLinkClicked:
            // Since a link was clicked, we want WebKit to ignore it
            [listener ignore];

            // Instead of opening it in the WebView, we want to open
            // the URL in the user's default browser
            clickURL = [actionInformation objectForKey:WebActionOriginalURLKey];
            NSString *action = [[[clickURL absoluteString] componentsSeparatedByString:@"/"] objectAtIndex:2];
           
            
            
            if ([action isEqualToString:@"assistant"])
            {
                [controller launchAssistant:@"asktoconfirm"];
            } else if ([action isEqualToString:@"uninstall"])
            {
                [rc showUninstaller:nil];
            } else if ([action isEqualToString:@"status"])
            {   //do nothing
            } else if ([action isEqualToString:@"logs"])
            {
                [[controller mainTabView] selectTabViewItemWithIdentifier:@"pureftpd.logging"];
            } else if ([action isEqualToString:@"vuser"])
            {
                [[controller mainTabView] selectTabViewItemWithIdentifier:@"pureftpd.users"];
            } else if ([action isEqualToString:@"vhost"])
            {
                [[controller mainTabView] selectTabViewItemWithIdentifier:@"pureftpd.hosts"];
            } else if ([action isEqualToString:@"macosx"])
            {
                [preferences showPreferences:nil];
                [preferences selectPreferencePaneByIdentifier:@"pureftpd.SystemPane"];
            } else if ([action isEqualToString:@"prefpane"])
            {
                [preferences showPreferences:nil];
            } else if ([action isEqualToString:@"anonymous"])
            {
                [preferences showPreferences:nil];
                [preferences selectPreferencePaneByIdentifier:@"pureftpd.AnonymousPane"];
            } else if ([action isEqualToString:@"auth"])
            {
                [preferences showPreferences:nil];
                [preferences selectPreferencePaneByIdentifier:@"pureftpd.AuthentificationPane"];
            } else if ([action isEqualToString:@"ssl"])
            {
                [preferences showPreferences:nil];
                [preferences selectPreferencePaneByIdentifier:@"pureftpd.SSLPane"];
            } else if ([action isEqualToString:@"diraliases"])
            {
                [preferences showPreferences:nil];
                [preferences selectPreferencePaneByIdentifier:@"pureftpd.DirAliasesPane"];
            } else 
            {
                [[NSWorkspace sharedWorkspace] openURL: [actionInformation objectForKey:WebActionOriginalURLKey]];
            }
            
            break;
        default:
            [listener use];
    }
}


@end
