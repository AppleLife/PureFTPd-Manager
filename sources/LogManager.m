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


#import "LogManager.h"


@interface LogManager(PrivateAPI)
- (void)_tryRead:(NSTimer *)sender;
@end

@implementation LogManager

// The pointer to the singleton instance
static LogManager *theLogManager = nil;

/* Get the singleton instance of this class */
+(id) getInstance
{
    // TODO: Mutex Begin
    if (theLogManager == nil) {
        theLogManager = [[LogManager alloc] init];
    }
    // TODO: Mutex End
    return theLogManager;
}


-(id) init 
{
    self = [super init];
    if (self)
    {
        theLogManager = self;
    }
    return self;
}


-(NSButton *)refreshButton
{
    return refreshButton;
}

- (void) awakeFromNib
{
    [logTable selectRow:0 byExtendingSelection:NO];
    [self start];
    
    
    // if((usersDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPStatsFile]) == nil)
    usersDictionary = [[NSMutableDictionary alloc] init];
    
   
   
    
    koctet = 1024;
    moctet = koctet*1024;
    goctet = moctet * 1024;
    toctet = goctet * 1024;
    

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(clearProgressField:)
                                                 name:NSThreadWillExitNotification
                                               object:nil];
    
    reloadingTables = NO;
    NSDictionary *preferences = nil;
    if (nil != (preferences = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile]))
    {
        if([[preferences objectForKey:PureFTPLogAutoUpdate] intValue] == 1){
            [self refreshAction:nil];
        } else {
             [self reloadTables:nil];
        }
        
    }
    
    [progressWheel setDisplayedWhenStopped:NO];
    
}

-(NSMutableDictionary *) usersDictionary {return usersDictionary;}
-(NSArray *) sortedArray {return sortedArray;}
-(NSTableView *)usersTable { return usersTable; }
-(NSTableView *)ftpTable { return ftpTable; }



#pragma mark 
#pragma mark ==> logTables DS & Delegate
// logTables DataSource
- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
    //NSMutableDictionary *myDict = [myUserStats dictionary];
    //NSMutableArray *keyArray = [NSMutableArray arrayWithArray:[usersDictionary allKeys]];
    //[keyArray removeObject:LASTLINE];
    
    if([tableView isEqualTo:logTable])
        return 1;
    else if ([tableView isEqualTo:usersTable])
    {
        if (sortedArray != nil){
            return [sortedArray count];
        } else {
            return 0;
        }
    }
    else if ([tableView isEqualTo:ftpTable])
    {
        if ((sortedArray != nil) && ([usersTable selectedRow]!=-1)) {
            return [[usersDictionary objectForKey:[[sortedArray objectAtIndex:[usersTable selectedRow]] objectForKey:@"account"]] count]-1;
        } else {
            return 0;
        }
    }
    return 1;
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn *)col row:(int)row
{
 
    
    NSArray *userArray;
    NSMutableDictionary *transferRecord;
    
    
    if ([tableView isEqualTo:logTable])    
        return NSLocalizedString(@"PureFTPd\nGeneral Informations",@"localized string");
    else if ([tableView isEqualTo:usersTable])
    {
        if (sortedArray != nil){
            return [[sortedArray objectAtIndex:row] objectForKey:@"account"];
        } else {
            return nil;
        }
    }
    else if ([tableView isEqualTo:ftpTable] && ([usersTable selectedRow] != -1))
    {
        if (sortedArray == nil){
            return nil;
        } else {
            userArray = [usersDictionary objectForKey:[[sortedArray objectAtIndex:[usersTable selectedRow]] objectForKey:@"account"]];
            transferRecord = [userArray objectAtIndex:row+1];
            NSString *transferT = [transferRecord objectForKey:@"tc_type"];
            NSString *file =  [transferRecord objectForKey:@"tc_filename"];
            
            if([[col identifier] isEqualToString:@"tc_type"])
            {
                if ([transferT isEqualToString:@"PUT"] || [transferT isEqualToString:@"created"])
                {
                    return [NSImage imageNamed: @"upload"];
                }
                else if ([transferT isEqualToString:@"GET"] || [transferT isEqualToString:@"sent"])
                {
                    return [NSImage imageNamed: @"download"];
                }
                else
                    return nil;
            }
            else if([[col identifier] isEqualToString:@"tc_size"])
            {
                return [self formatSize:[NSNumber numberWithDouble:[[transferRecord objectForKey:@"tc_size"] doubleValue]]];
            }
            else if([[col identifier] isEqualToString:@"tc_filename"])
            {
                return [file lastPathComponent];
            }
            else if([[col identifier] isEqualToString:@"tc_date"])
            {
                return [transferRecord objectForKey:@"tc_date"];
            }
        }            
    }
        
    return nil;
}

// logTables delegates
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    if ([tableView isEqualTo:logTable]) {
         //[ftpTable deselectAll:self];
        [usersTable deselectAll:self];
        [clearButton setEnabled:NO];
        [logTab selectTabViewItemAtIndex:0];
    }
    else if ([tableView isEqualTo:usersTable])  {
        [logTable deselectAll:self];
        [clearButton setEnabled:YES];
        [logTab selectTabViewItemAtIndex:1];
        
    }
    else if ([tableView isEqualTo:ftpTable])
    {
        
        //NSMutableDictionary *myDict = [myUserStats dictionary];
        //NSMutableArray *keyArray = [NSMutableArray arrayWithArray:[usersDictionary allKeys]];
        //[keyArray removeObject:LASTLINE];
        
        NSArray *userArray= [usersDictionary objectForKey:[[sortedArray objectAtIndex:[usersTable selectedRow]] objectForKey:@"account"]];
        NSMutableDictionary *transferRecord = [userArray objectAtIndex:row+1];
        
        NSString *filePath = [transferRecord objectForKey:@"tc_filename"];
        NSString *userIP = [transferRecord objectForKey:@"UserIP"];
        
        [fileField setStringValue:[filePath stringByDeletingLastPathComponent]];
        [ipField setStringValue: userIP];
        
    }
    return YES;
}



- (void)tableViewSelectionIsChanging:(NSNotification *)aNotification
{
    //NSLog(@"SelectionIsChanging");
    
    if ([[aNotification object] isEqualTo:usersTable])    
    {
        [fileField setStringValue:@""];
        [ipField setStringValue:@""];
        [ftpTable reloadData];
        if ([usersTable selectedRow] != -1){
            [self refreshMenu];
        }
    }
     
    
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification
{
    
    if ([[aNotification object] isEqualTo:usersTable])    
    {
        [ftpTable deselectAll:nil];
    }
}



- (float)splitView:(NSSplitView *)sender constrainMaxCoordinate:(float)proposedMax ofSubviewAt:(int)offset
{
    //NSLog(@"%f", proposedMax);
    return 300.0;
}

- (float)splitView:(NSSplitView *)sender constrainMinCoordinate:(float)proposedMin ofSubviewAt:(int)offset
{
    //NSLog(@"%f", proposedMin);
    return 90.0;
}
- (BOOL)splitView:(NSSplitView *)sender canCollapseSubview:(NSView *)subview
{
    return YES;
}

#pragma mark 
#pragma mark ==> serverLogTV actions

- (void)start
{
    MKLogfileReader	*reader;
    
    if(timer != nil)
        [NSException raise:NSInternalInconsistencyException format:@"%s already started", __PRETTY_FUNCTION__];
    cycle = 0;
    readerList = [[NSMutableArray allocWithZone:[self zone]] init];
    
    reader = [[[MKLogfileReader allocWithZone:[self zone]] initWithFilename:PureFTPDefaultLogFile] autorelease];
    if([reader open])
	[readerList addObject:reader];
    else
	NSRunAlertPanel(nil, @"Failed to open logfile at: %@", @"Cancel", nil, nil, PureFTPDefaultLogFile);
	
    [self _tryRead:nil];
    timer = [NSTimer scheduledTimerWithTimeInterval:5 target:self selector:@selector(_tryRead:) userInfo:nil repeats:YES];
}

- (void)_tryRead:(NSTimer *)sender
{
    NSTextStorage 	 *textStorage;
    NSEnumerator	 *readerEnum;
    MKLogfileReader	 *reader;
    NSString		 *message;
    
    textStorage = [serverLogTV textStorage];
    [textStorage beginEditing];
    readerEnum = [readerList objectEnumerator];
    while((reader = [readerEnum nextObject]) != nil)
    {
        while((message = [reader nextMessage]) != nil)
	{
            unsigned int location = [textStorage length];
            [textStorage replaceCharactersInRange:NSMakeRange(location, 0) withString:message];
            
	}
    }
    if([textStorage length] > 50*1024)
        [textStorage deleteCharactersInRange:NSMakeRange(0, [textStorage length] - 50*1024)];
    [textStorage endEditing];
    [serverLogTV scrollRangeToVisible:NSMakeRange([textStorage length], 1)];
    
}
- (void)stop
{
    NSEnumerator	*readerEnum;
    MKLogfileReader	*reader;
    
    if(timer == nil)
        [NSException raise:NSInternalInconsistencyException format:@"%s not started", __PRETTY_FUNCTION__];
    
    [timer invalidate];
    timer = nil;
    
    readerEnum = [readerList objectEnumerator];
    while((reader = [readerEnum nextObject]) != nil)
        [reader close];
    [readerList release];
    readerList = nil;
    
}

-(void) reloadUserStats:(id)anObject
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
    NSDictionary *preferences = nil;
    if (nil != (preferences = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile]))
    {
        NSString *logPath = [preferences objectForKey:PureFTPLogLocation];
        NSString *logFormat = [preferences objectForKey:PureFTPLogFormat];
        NSString *pattern = nil;
        if ([logFormat isEqualToString:@"CLF"])
            pattern = [NSString stringWithString:CLF_PATTERN];
        else if ([logFormat isEqualToString:@"W3C"])
            pattern = [NSString stringWithString:W3C_PATTERN];
        if ([[preferences objectForKey:PureFTPLogNiceThread] intValue] == 1)
       {
           double priority = [NSThread  threadPriority] / 2;
           //NSLog(@"Nicely start data processing of %@ with priority : %f...", logPath, priority);
           [NSThread setThreadPriority:priority];
       }
        
        myUserStats = [[UserStatsController alloc] init];
        [myUserStats parseFile:logPath withPattern: pattern];
        
        [myUserStats release];
		[self reloadTables:nil];
      
        
    }
    [pool release];
    //[NSThread exit];
    return;
}


/*
- (void) threadDied:(NSNotification *)notification
{
   [self reloadTables:nil]; 
}*/

-(void) reloadTables:(id)sender
{
  
    if (reloadingTables)
        return;
    reloadingTables = YES;
    
    //[usersDictionary removeAllObjects];
    if(usersDictionary != nil){
        [usersDictionary release];
        usersDictionary = nil;
    }
    
    NSDictionary *fileDict = [NSDictionary dictionaryWithContentsOfFile:PureFTPStatsFile];
    if (fileDict != nil){
        //[usersDictionary addEntriesFromDictionary:fileDict];
         usersDictionary = [[NSMutableDictionary alloc] initWithDictionary:fileDict];
    } else {
        sortedArray = nil;
        [self clearProgressField:nil];
        [usersTable reloadData];
        [ftpTable reloadData];
        reloadingTables = NO;
        return;
    }
    
    // Sort users by name
    NSMutableArray *keyArray = [NSMutableArray arrayWithArray:[usersDictionary allKeys]];
    [keyArray removeObject:LASTLINE];
    
    if ([keyArray count] < 1)
    { // FTPStats exists but does not contain any user, we'd better exit
        sortedArray = nil;
        [self clearProgressField:nil];
        [usersTable reloadData];
        [ftpTable reloadData];
        reloadingTables = NO;
        return;
    }
    
    
    
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
        
        NSSortDescriptor *lastNameDescriptor=[[NSSortDescriptor alloc] initWithKey:@"account" 
                                                                          ascending:YES
                                                                           selector:@selector(caseInsensitiveCompare:)];
        NSArray *sortDescriptors=[NSArray arrayWithObject:lastNameDescriptor];
        [lastNameDescriptor release];
        
        if (sortedArray)
            [sortedArray release];
        sortedArray=[[NSArray alloc] initWithArray:[usersArray sortedArrayUsingDescriptors:sortDescriptors]];
    } else {
        if (sortedArray)
            [sortedArray release];
        sortedArray = [[NSArray alloc] initWithArray:usersArray];
    }
    
    [usersArray release];
    
    [usersTable reloadData];
    [ftpTable reloadData];
    reloadingTables = NO;
    //[self performSelectorOnMainThread:@selector(clearProgressField:) withObject:nil waitUntilDone:YES];
    [self clearProgressField:nil];
}

- (void)clearProgressField:(NSNotification *)notification
{
    [progressField setStringValue:@""];
    [progressWheel stopAnimation:self];
    [progressField setStringValue:@""];
}

-(IBAction) refreshAction:(id)sender
{
    NSDictionary *preferences = nil;
    preferences = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
    if (preferences && ([[preferences objectForKey:PureFTPLogOnOff] intValue] == 1))
    {
        [progressWheel startAnimation:self];
        [progressField setStringValue:NSLocalizedString(@"Updating Users Statistics...", @"Updating users statistics")];
        
        [NSThread detachNewThreadSelector:@selector(reloadUserStats:) toTarget:self withObject:nil ];
    }
    else
    {
        [self loggingAlert];
    }
}

-(IBAction) cancelThread:(id)sender
{
    //[NSThread exit];
}

-(void) loggingAlert
{
    NSBeginAlertSheet(NSLocalizedString(@"No logging facility activated",@"No logging facility activated"), 
                      NSLocalizedString(@"Yes",@"localized string"), 
                      NSLocalizedString(@"No",@"localized string"), NULL,
                      [NSApp mainWindow], self, @selector(sheetDidEnd:returnCode:contextInfo:), 
                      NULL, NULL, 
                      NSLocalizedString(@"You need to enable logging on this server.\nDo you want to configure it now?",@"localized string"),
                      nil);
}


- (void)sheetDidEnd: (NSWindow *)sheet
         returnCode: (int)returnCode
        contextInfo: (void *)contextInfo
{
    int nice = (int) contextInfo;
    if ((returnCode == NSAlertDefaultReturn) && (nice != 1))
    {   
        // open the preferences pane
        [[MVPreferencesController sharedInstance] showPreferences:self];
    }
   

    
    [NSApp stopModal];
    
}


- (void)createYearMenu
{
    NSMutableDictionary *userTraffic;
    NSMenu *yearMenu = [[[NSMenu alloc] initWithTitle:@"yearMenu"] autorelease];
    
    int userRow= [usersTable selectedRow];
    if (userRow != -1){
        userTraffic = [[usersDictionary objectForKey:[[sortedArray objectAtIndex:userRow] objectForKey:@"account"]] objectAtIndex:0];
        
        NSArray *yearKeys = [userTraffic allKeys];
        NSEnumerator *yearEnum = [yearKeys objectEnumerator];
        NSString *yKey;
        
        while((yKey = [yearEnum nextObject]))
        {
            [yearMenu addItemWithTitle:yKey
                                action:@selector(createMonthMenuForYear:)
                         keyEquivalent:@""];
            [[yearMenu itemWithTitle:yKey] setTag:[yKey intValue]];
            [[yearMenu itemWithTitle:yKey] setTarget:self];
            
        }
    }
    
    [graphYearPop setMenu:yearMenu];
    [graphYearPop selectItemAtIndex:0];
    
}

- (void)createMonthMenuForYear:(id)sender
{   
    NSMutableDictionary *userTraffic;
    int userRow= [usersTable selectedRow];
    
    // Month menu will have 12 months + 1 separator + 1 All Year = 14 items
    int i=12;
    NSMenu *monthMenu = [[[NSMenu alloc] initWithTitle:@"monthMenu"] autorelease];
    for (i=12; i>0; i--)
    {
        NSMenuItem *item = [[[NSMenuItem alloc] init] autorelease];
        [item setTitle:@"delete_me"];
        [monthMenu addItem:item];
    }
    
    
    if (userRow != -1){
        userTraffic = [[usersDictionary objectForKey:[[sortedArray objectAtIndex:userRow] objectForKey:@"account"]] objectAtIndex:0];
        NSArray *yearKeys = [userTraffic allKeys];
        NSEnumerator *yearEnum = [yearKeys objectEnumerator];
        NSString *yKey, *mKey;
       
        
        
        while((yKey = [yearEnum nextObject]))
        {
            
            if ([yKey intValue] == [sender tag])
            {
                
                [monthMenu insertItemWithTitle: NSLocalizedString(@"All Year",@"All Year")
                                        action: @selector(refreshUserGraph:) 
                                 keyEquivalent:@""
                                       atIndex:0];
                [[monthMenu itemWithTitle:NSLocalizedString(@"All Year",@"All Year")] setTag:0];
                [[monthMenu itemWithTitle:NSLocalizedString(@"All Year",@"All Year")] setTarget:self];
                [monthMenu insertItem:[NSMenuItem separatorItem] atIndex:1];
                
                NSArray *monthKeys = [[userTraffic objectForKey:yKey] allKeys];
                NSEnumerator *monthEnum = [monthKeys objectEnumerator];
                
                while((mKey = [monthEnum nextObject]))
                {
                    NSString *niceOutput = nil;
                    
                    if (![mKey isEqualToString:@"yearTotal"])
                    {
                        switch ([mKey intValue])
                        {
                            case 0:
                                break;
                            case 1:
                                niceOutput = NSLocalizedString(@"January",@"month of january");
                                break;
                            case 2:
                                niceOutput = NSLocalizedString(@"February",@"month of February");
                                break;
                            case 3:
                                niceOutput = NSLocalizedString(@"March",@"month of March");
                                break;
                            case 4:
                                niceOutput = NSLocalizedString(@"April",@"month of April");
                                break;
                            case 5:
                                niceOutput = NSLocalizedString(@"May",@"month of May");
                                break;
                            case 6:
                                niceOutput = NSLocalizedString(@"June",@"month of June");
                                break;
                            case 7:
                                niceOutput = NSLocalizedString(@"July",@"month of July");
                                break;
                            case 8:
                                niceOutput = NSLocalizedString(@"August",@"month of August");
                                break;
                            case 9:
                                niceOutput = NSLocalizedString(@"September",@"month of September");
                                break;
                            case 10:
                                niceOutput = NSLocalizedString(@"October",@"month of November");
                                break;
                            case 11:
                                niceOutput = NSLocalizedString(@"November",@"month of November");
                                break;
                            case 12:
                                niceOutput = NSLocalizedString(@"December",@"month of December");
                                break;
                        }
                                               
                        NSMenuItem *anItem = [monthMenu itemAtIndex:[mKey intValue] + 1];
                        [anItem setTitle:niceOutput];
                        [anItem setTag:[mKey intValue]];
                        [anItem setAction:@selector(refreshUserGraphView)];
                        [anItem setTarget:[GraphController getInstance]]; 
                        
                    }
                    
                }
            }
        }
        
       
        
        
        
    }
    
    // Clear empty NSMenuItem
    NSMenuItem *delItem;
    NSEnumerator *itemEnum = [[monthMenu itemArray] objectEnumerator];
    while ((delItem = [itemEnum nextObject]))
    {
        if ([[delItem title] isEqualToString:@"delete_me"])
            [monthMenu removeItem:delItem];
    }
    
    
    [graphMonthPop setMenu:monthMenu];
    [self refreshUserGraph:nil];
}

- (void)refreshMenu
{
    
    [self createYearMenu];
    [self createMonthMenuForYear:[graphYearPop selectedItem]];
}

-(void)refreshUserGraph:(id) sender
{
    //[self createGraphDateMenu];
   [[GraphController getInstance] refreshUserGraphView];

}

-(NSNumber *)formatSize:(NSNumber *)number
{
    NSNumberFormatter *numberFormat = [[[NSNumberFormatter alloc] init] autorelease];
    if ([number doubleValue] < 1024){
        [numberFormat setFormat:@"#,##0 B"];
        [[[ftpTable tableColumnWithIdentifier:@"tc_size"] dataCell] setFormatter:numberFormat];
        return number;
    }    
    else if (([number doubleValue] >= 1024) && ([number doubleValue] < moctet))
    {
        [numberFormat setFormat:@"#,##0 KB"];
        [[[ftpTable tableColumnWithIdentifier:@"tc_size"] dataCell] setFormatter:numberFormat];
        return [NSNumber numberWithInt:[number intValue]/koctet];
    }
    else if (([number doubleValue] >= moctet) && ([number doubleValue] < goctet))
    {
        [numberFormat setFormat:@"#,##0 MB"];
        [[[ftpTable tableColumnWithIdentifier:@"tc_size"] dataCell] setFormatter:numberFormat];
        return [NSNumber numberWithInt:[number intValue]/moctet];
    }
    else if ([number doubleValue] >= goctet)
    {
        [numberFormat setFormat:@"#,##0 GB"];
        [[[ftpTable tableColumnWithIdentifier:@"tc_size"] dataCell] setFormatter:numberFormat];
        return [NSNumber numberWithInt:[number doubleValue]/goctet];
    }

    return nil;
}


- (IBAction)printServerLog:(id)sender
{
}


- (IBAction)clearLog:(id)sender
{
    
    // index for usersTable
    int index;
    
    if ((index = [usersTable selectedRow]) != -1)
    {
        NSMutableArray *usersArray = [[NSMutableArray alloc] initWithArray:[usersDictionary allKeys]];
        [usersArray removeObject:LASTLINE];
        //NSLog(@"%d, %@",index, [usersArray objectAtIndex:index]);
        [usersDictionary removeObjectForKey:[usersArray objectAtIndex:index]];
        [usersDictionary writeToFile:PureFTPStatsFile atomically:YES];
        [usersArray release];
        [self reloadTables:nil];
    }
   
}








@end
