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

#import "MySQLCC.h"
#import "defines.h"
#include <pwd.h>
#include <grp.h>

@implementation MySQLCC

- (void) awakeFromNib
{
    [self setUserAndGroupPopup];
    [self loadPreferences];
    [self enableSaveButton];
}

- (IBAction)cancel:(id)sender
{
    [NSApp stopModal];
}


- (IBAction)save:(id)sender
{
    if([self prepareDatabase])
    {
        [self savePreferences];
    }
    
    
    [NSApp stopModal];
}

- (IBAction)useDefaultID:(id)sender
{
    switch ([sender state]){
        case NSOnState:
            [userPopUp setEnabled:YES];
            [groupPopUp setEnabled:YES];
            break;
        case NSOffState:
            [userPopUp setEnabled:NO];
            [groupPopUp setEnabled:NO];
            break;
    }
}

- (BOOL)prepareDatabase
{   
    MCPResult *theRes;
    NSDictionary *theDict;
    NSArray *theColNames;
    int i, j;
    BOOL shouldCreateTable = YES;
    
    mySQLConnection = [[MCPConnection alloc] initToHost:[sqlHost stringValue] withLogin:[sqlUsername stringValue] password:[sqlPassword stringValue] usingPort:[sqlPort intValue]];
    if (![mySQLConnection selectDB:[sqlDatabase stringValue]])
    {
        // DATABASE DOESN'T EXIST : Let's create it.
        NSString *qString = [NSString stringWithFormat:@"CREATE DATABASE IF NOT EXISTS %@", [sqlDatabase stringValue]];
        [mySQLConnection queryString:qString];
        
        if (![mySQLConnection selectDB:[sqlDatabase stringValue]]){
            NSRunAlertPanel(NSLocalizedString(@"Error connecting to MySQL", @"Error connecting to MySQL"),
                            NSLocalizedString(@"Database setup aborted! Please check that your MySQL server is running", @"Database setup aborted!Please check that your MySQL server is running"),
                            nil, nil, nil);
            [mySQLConnection release];
            return NO;
        }
    }
    
    theRes = [mySQLConnection listTablesLike:@"users"];
    theColNames = [theRes fetchFieldsName];
    i = 0;
    
    while (theDict = [theRes fetchRowAsDictionary]){
        for (j=0; j<[theColNames count]; j++){
            if ([[theDict objectForKey:[theColNames objectAtIndex:j]] isEqualToString:@"users"])
                shouldCreateTable=NO;
        }
        i++;
    }
    
    if (shouldCreateTable){
        // Create the virtual user table
        NSString *qString = [NSString stringWithString:@"CREATE TABLE `users` (`Login` char(255) NOT NULL default '', `Password` char(255) NOT NULL default '', `Uid` int(5) NOT NULL default '-1', `Gid` int(5) NOT NULL default '-1', `Dir` char(255) NOT NULL default '', `QuotaFiles` int(11) default NULL, `QuotaSize` int(11) default NULL, `ULRatio` int(11) default NULL, `DLRatio` int(11) default NULL, `ULBandwidth` int(11) default NULL, `DLBandWidth` int(11) default NULL, PRIMARY KEY(`Login`)) Type=InnoDB"];

        [mySQLConnection queryString:qString];
    }
    
    [mySQLConnection release];
    return YES;
}


- (void)loadPreferences
{
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    NSString *string = nil;
    if ((string = [preferences objectForKey:PureFTPMySQLHost]) == nil)
        [sqlHost setStringValue:@""];
    else
        [sqlHost setStringValue:[preferences objectForKey:PureFTPMySQLHost]];
    if ((string = [preferences objectForKey:PureFTPMySQLPort]) != nil)
        [sqlPort setStringValue:string];
    else
        [sqlPort setStringValue:@"3306"];
    
    if ((string = [preferences objectForKey:PureFTPMySQLDatabase]) != nil)
        [sqlDatabase setStringValue:string];
    else
        [sqlDatabase setStringValue:@"pureftpd"];
    
    if ((string = [preferences objectForKey:PureFTPMySQLUsername]) != nil)
        [sqlUsername setStringValue:string];
    else
        [sqlUsername setStringValue:@"root"];
    if((string = [preferences objectForKey:PureFTPMySQLPassword]) == nil)
        [sqlPassword setStringValue:@""];
    else
        [sqlPassword setStringValue:[preferences objectForKey:PureFTPMySQLPassword]];
    NSNumber *crypt = [preferences objectForKey:PureFTPMySQLCrypt];
	if (crypt != nil){
		[cryptSwitch setState:[crypt intValue]];
	} else {
		[cryptSwitch setState:NSOnState];
	}
    
	[sqlTransactionSwitch setState:[[preferences objectForKey:PureFTPMySQLUseTrans] intValue]];

	
    [defaultIDSwitch setState:[[preferences objectForKey:PureFTPMySQLUseDefaultID] intValue]];
    switch ([defaultIDSwitch state]){
        case NSOnState:
            [userPopUp setEnabled:YES];
            [groupPopUp setEnabled:YES];
            break;
        case NSOffState:
            [userPopUp setEnabled:NO];
            [groupPopUp setEnabled:NO];
            break;
    }
    
    if ((string =[preferences objectForKey:PureFTPMySQLDefaultUID]) != nil)
        [userPopUp selectItemWithTitle:string];
    else
        [userPopUp selectItemWithTitle:@"ftpvirtual"];
    if ((string =[preferences objectForKey:PureFTPMySQLDefaultGID]) != nil)
        [groupPopUp selectItemWithTitle:string];
    else
        [groupPopUp selectItemWithTitle:@"ftpgroup"];
    
    [preferences release];
}

- (void)savePreferences
{
    BOOL addAuthMethod = YES;
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    NSMutableArray *authMethods = [[NSMutableArray alloc] initWithArray:[preferences objectForKey:PureFTPAuthentificationMethods]];
    NSMutableDictionary *infoDict = [[NSMutableDictionary alloc] init];
    
    NSEnumerator *authEnum = [authMethods objectEnumerator];
    id entry;
    while (entry = [authEnum nextObject]){
        if ([[entry objectForKey:@"auth.type"] isEqualToString:@"MySQL"])
            addAuthMethod = NO;
    }
    
    if(addAuthMethod){
        [infoDict setObject:@"MySQL" forKey:@"auth.type"];
        [infoDict setObject:PureFTPMySQLFile forKey:@"auth.file"];
        [authMethods addObject:infoDict];
        [preferences setObject:authMethods forKey:PureFTPAuthentificationMethods];
    }
	
    NSNumber *crypt = [[NSNumber alloc] initWithInt:[cryptSwitch state]];
	NSNumber *defaultID = [[NSNumber alloc] initWithInt:[defaultIDSwitch state]];
    NSNumber *useTransaction = [[NSNumber alloc] initWithInt:[sqlTransactionSwitch state]];
    
    
    [preferences setObject:[sqlHost stringValue] forKey:PureFTPMySQLHost];
    [preferences setObject:[sqlPort stringValue] forKey:PureFTPMySQLPort];
    [preferences setObject:[sqlDatabase stringValue] forKey:PureFTPMySQLDatabase];
    [preferences setObject:[sqlUsername stringValue] forKey:PureFTPMySQLUsername];
    [preferences setObject:[sqlPassword stringValue] forKey:PureFTPMySQLPassword];
	[preferences setObject:crypt forKey:PureFTPMySQLCrypt];
	
	
	[preferences setObject:defaultID forKey:PureFTPMySQLUseDefaultID];
    if ([defaultIDSwitch state]){
        [preferences setObject:[userPopUp title] forKey:PureFTPMySQLDefaultUID];
        [preferences setObject:[groupPopUp title] forKey:PureFTPMySQLDefaultGID];
    }
    
    [preferences setObject:useTransaction forKey:PureFTPMySQLUseTrans];
    
    NSNumber *update = [[NSNumber alloc] initWithInt:1];
    [preferences setObject:update forKey:PureFTPPrefsUpdated];
    
    //NSLog(@"Saving PureFTPD preferences - Authentification Methods");
    [preferences writeToFile:PureFTPPreferenceFile atomically:YES];
    [self saveMySQLConf];
    // Broadcast update
    [[NSNotificationCenter defaultCenter] postNotificationName:@"reloadAuthMethods" object:nil];
    
    [defaultID release];
    [useTransaction release];
	[crypt release];
    [update release];
    [authMethods release];
    [preferences release];
}

- (void)saveMySQLConf
{
    NSString *transaction = nil;
    NSString *defaultUID = @"";
    NSString *defaultGID = @"";
	NSString *crypted = @"cleartext";
    
	if ([cryptSwitch state])
        crypted = @"crypt";
	
    if ([sqlTransactionSwitch state])
        transaction = @"MySQLTransactions On";
    else
        transaction = @"MySQLTransactions Off";
            
    if([defaultIDSwitch state]){
        defaultUID = [NSString stringWithFormat:@"MYSQLDefaultUID %d", [[userPopUp selectedItem] tag]];
        defaultGID = [NSString stringWithFormat:@"MYSQLDefaultGID %d", [[groupPopUp selectedItem] tag]];
    } 
    
    NSString *confFile = [NSString stringWithFormat:@"MYSQLServer %@\n\
    MYSQLPort   %@\n\
    MYSQLUser   %@\n\
    MYSQLPassword   %@\n\
    MYSQLDatabase   %@\n\
    %@\n\
    %@\n\
    %@\n\
    MYSQLCrypt      %@\n\
    MYSQLSocket     /tmp/mysql.sock\n\
    MYSQLGetUID     SELECT Uid FROM users WHERE Login=\"\\L\"\n\
    MYSQLGetGID     SELECT Gid FROM users WHERE Login=\"\\L\"\n\
    MYSQLGetPW      SELECT Password FROM users WHERE Login=\"\\L\"\n\
    MYSQLGetDir     SELECT Dir FROM users WHERE Login=\"\\L\"\n\
    MySQLGetQTAFS  SELECT QuotaFiles FROM users WHERE Login=\"\\L\"\n\
    MySQLGetQTASZ  SELECT QuotaSize FROM users WHERE Login=\"\\L\"\n\
    MySQLGetRatioUL SELECT ULRatio FROM users WHERE Login=\"\\L\"\n\
    MySQLGetRatioDL SELECT DLRatio FROM users WHERE Login=\"\\L\"\n\
    MySQLGetBandwidthUL SELECT ULBandwidth FROM users WHERE Login=\"\\L\"\n\
    MySQLGetBandwidthDL SELECT DLBandwidth FROM users WHERE Login=\"\\L\"\n", 
        [sqlHost stringValue], [sqlPort stringValue], [sqlUsername stringValue], [sqlPassword stringValue], [sqlDatabase stringValue], defaultUID, defaultGID, transaction, crypted];
    
    [confFile writeToFile:PureFTPMySQLFile atomically:NO];
    NSNumber *posixPerm = [[NSNumber alloc] initWithInt:0600];
    
    NSDictionary *attributes =[NSDictionary dictionaryWithObject:posixPerm forKey:@"NSFilePosixPermissions"];
    [[NSFileManager defaultManager] changeFileAttributes:attributes atPath:PureFTPMySQLFile];
}

- (void)setUserAndGroupPopup
{
    NSString *username;
    NSString *groupname;
    struct passwd *userInfo;
    struct group *groupInfo;
    
    [userPopUp removeAllItems];
    [groupPopUp removeAllItems];
    
    while((userInfo=getpwent()) != NULL)
    {
        username = [NSString stringWithFormat:@"%s", userInfo->pw_name];
        [userPopUp addItemWithTitle:username];
        [[userPopUp lastItem] setTag: (int)userInfo->pw_uid];
    }
    
    while((groupInfo=getgrent()) != NULL)
    {
        groupname = [NSString stringWithFormat:@"%s", groupInfo->gr_name];
        [groupPopUp addItemWithTitle:groupname];
        [[groupPopUp lastItem] setTag: groupInfo->gr_gid];
    }
}

- (void)controlTextDidChange:(NSNotification *)aNotification
{
    [self enableSaveButton];
}

- (void)enableSaveButton
{
    if ((![[sqlHost stringValue] isEqualToString:@""]) && (![[sqlPort stringValue] isEqualToString:@""]) && (![[sqlDatabase stringValue] isEqualToString:@""]) && 
        (![[sqlUsername stringValue] isEqualToString:@""]) && (![[sqlPassword stringValue] isEqualToString:@""]))
        [saveButton setEnabled:YES];
    else
        [saveButton setEnabled:NO];
}

@end
