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

#import "AuthentificationPane.h"
#import "defines.h"

@implementation AuthentificationPane
- (id) initWithBundle:(NSBundle *) bundle {
    self = [super initWithBundle:bundle] ;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                                        selector:@selector(reloadAuthMethods)
                                                 name:@"reloadAuthMethods" object:nil];
    return self ;
}

- (void) dealloc {
    [authMethods release];  
    [[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

-(void) loadPreferences{
    [createHomeSwitch setState:[[pureFTPPreferences objectForKey:PureFTPCreateHomeDir] intValue]];
}

-(void) savePreferences{
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    
    NSNumber *createHome = [[NSNumber alloc] initWithInt:[createHomeSwitch state]];  
    [preferences setObject:authMethods forKey:PureFTPAuthentificationMethods];
    [preferences setObject:createHome forKey:PureFTPCreateHomeDir]; 
    
    NSNumber *update = [[NSNumber alloc] initWithInt:1];
    [preferences setObject:update forKey:PureFTPPrefsUpdated];
    
    NSLog(@"Saving PureFTPD preferences - Authentification Methods");
    [preferences writeToFile:PureFTPPreferenceFile atomically:YES];
    [createHome release];
    [update release];
    [preferences release];
    modified = NO;
}



- (IBAction)closeAddSheet:(id)sender
{
    [NSApp stopModal];
}

- (IBAction)chooseFile:(id)sender
{
    int result;
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
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
    result = [oPanel runModalForDirectory:NSHomeDirectoryForUser(activeUser) file:nil types:nil];
    if (result == NSOKButton)
        [authFileField setStringValue:[[oPanel filenames] objectAtIndex:0]];
        
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(int)returnCode contextInfo:(void *)contextInfo
{
    switch (moreInfo){
        case MySQL:
            [authWindow close];
            [self showMySQLSheet];
            break;
        default:
            break;
    }
}

- (BOOL)validateMenuItem:(id)menuItem
{
    NSEnumerator *authEnum = [authMethods objectEnumerator];
    id entry;
    while (entry = [authEnum nextObject]){
        if ([[entry objectForKey:@"auth.type"] isEqualToString:[menuItem title]])
            return NO;
    }
    
    return YES;
}

- (IBAction)showAddSheet:(id)sender
{
    moreInfo = None;
    [authFileField setStringValue:@""];
    
    [NSApp beginSheet: authWindow
            modalForWindow: [NSApp mainWindow]
            modalDelegate: self
            didEndSelector: @selector(sheetDidEnd:returnCode:contextInfo:)
            contextInfo: nil];
    [NSApp runModalForWindow: authWindow];
    // Sheet is up here.
    [NSApp endSheet: authWindow];
    [authWindow orderOut: self];
}



- (IBAction)addAuthMethod:(id)sender
{
    if (![[authTypePopUp selectedItem] isEnabled])
    {
        [NSApp stopModal];
        return;
    }
    NSMutableDictionary *infoDict;
    
        infoDict = [[NSMutableDictionary alloc] init];
        [infoDict setObject:[authTypePopUp title] forKey:@"auth.type"];
        [infoDict setObject:[authFileField stringValue] forKey:@"auth.file"];
    
        [authMethods addObject:infoDict];
        [authMethodTable reloadData];
        [infoDict release];
    
    //else if 
    [NSApp stopModal];
    modified = YES;
}


- (IBAction)removeAuthMethod:(id)sender
{
    int row=[authMethodTable selectedRow];
    [authMethods removeObjectAtIndex:row];
    [authMethodTable reloadData];
    [pureFTPPreferences setObject:authMethods forKey:PureFTPAuthentificationMethods];
    [pureFTPPreferences writeToFile:PureFTPPreferenceFile atomically:YES];
    
    modified = YES;
}


- (IBAction)authMethodSelected:(id)sender{
    if ([[sender titleOfSelectedItem] isEqualToString:@"Unix"])
    {
        [authFileField setStringValue:@""];
        [authFileField setEnabled:NO];
        [authFileButton setEnabled:NO];
    }
    else if ([[sender titleOfSelectedItem] isEqualToString:@"PAM"])
    {
        [authFileField setStringValue:@"/etc/pam.d/pure-ftpd"];
        [authFileField setEnabled:NO];
        [authFileButton setEnabled:NO];
    }
    else if ([[sender titleOfSelectedItem] isEqualToString:@"PureDB"])
    {
        [authFileField setStringValue:@"/etc/pure-ftpd/pureftpd.pdb"];
        [authFileField setEnabled:NO];
        [authFileButton setEnabled:NO];
    }
    else if ([[sender titleOfSelectedItem] isEqualToString:@"MySQL"])
    {
        moreInfo = MySQL;
        [NSApp stopModal];
    }
       
    else
    {   [authFileField setStringValue:@""];
        [authFileField setEnabled:YES];
        [authFileButton setEnabled:YES];
    }
}

- (IBAction)editType:(id)sender
{
    [self showMySQLSheet];
}

- (void) showMySQLSheet 
{
    [NSApp beginSheet: mySQLSheet
       modalForWindow: [NSApp mainWindow]
        modalDelegate: self
       didEndSelector: nil
          contextInfo: nil];
    [NSApp runModalForWindow: mySQLSheet];
    // Sheet is up here.
    [NSApp endSheet: mySQLSheet];
    [mySQLSheet orderOut: self];
}

// Authentification methods NSTableView Datasource

- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
	return [authMethods count];
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn *)col row:(int)row
{
        NSMutableDictionary *infoDict = [NSMutableDictionary dictionaryWithDictionary:[authMethods objectAtIndex:row]];
	return [infoDict valueForKey:[col identifier]];
}

// Authentification methods NSTableView delegates
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex{
    [removeAuthButton setEnabled:YES];
    id entry = [authMethods objectAtIndex:rowIndex];
    if ([[entry objectForKey:@"auth.type"] isEqualToString:@"MySQL"])
        [editButton setEnabled:YES];
    else
        [editButton setEnabled:NO];
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)aNotification{
    if([authMethodTable selectedRow] == -1){
        [removeAuthButton setEnabled:NO];
        [editButton setEnabled:NO];
    }
}

- (IBAction)didModify:(id)sender
{
    modified = YES;
}




- (void) mainViewDidLoad {
    pureFTPPreferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    authMethods = [[NSMutableArray alloc] initWithArray:[pureFTPPreferences objectForKey:PureFTPAuthentificationMethods]];
    
    if ([[pureFTPPreferences objectForKey:OSVersion] intValue] >= 0x1030)
    {
        [authTypePopUp removeItemWithTitle:@"Unix"];
    }
    
    else 
    {
        [authTypePopUp removeItemWithTitle:@"PAM"];
    }
    
    modified=NO;
    [self loadPreferences];
    
}


- (void) willUnselect {
    if(modified)
        [self savePreferences];    

    [[NSDistributedNotificationCenter defaultCenter] postNotificationName:@"reloadAuthMethods" object:@"org.pureftpd.osx"];
    [pureFTPPreferences release];
    
}

- (void)reloadAuthMethods
{
    if (pureFTPPreferences)
        [pureFTPPreferences release];
    if(authMethods)
        [authMethods release];
    
    pureFTPPreferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    authMethods = [[NSMutableArray alloc] initWithArray:[pureFTPPreferences objectForKey:PureFTPAuthentificationMethods]];
    [authMethodTable reloadData];
}

@end

