/*
    PureFTPd Manager
    Copyright (C) 2003 Jean-Matthieu Schaffhauser <jean-matthieu@users.sourceforge.net>

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

#import "UserManager.h"

#include <puredb_write.h>

// The pointer to the singleton instance
static UserManager *theUserManager = nil;

@implementation UserManager

- (id)init
{
	self = [super init];
	if (self) {
		users = [[NSMutableArray alloc] init];
                passwdFile = [[NSString alloc] init];
                allowedIP = [[NSMutableArray alloc] init];
                deniedIP = [[NSMutableArray alloc] init]; 
                userListUpdated=FALSE;
                pureController = [PureController getInstance];
	}
	return self;
}

- (void)dealloc
{
	[users release];
        [allowedIP release];
        [deniedIP release];
        [passwdFile release];
        [pureController release];
	[super dealloc];
}


/* Get the singleton instance of this class */
+(id) getInstance
{
    	// TODO: Mutex Begin
	if (theUserManager == nil) {
		theUserManager = [[UserManager alloc] init];
	}
	// TODO: Mutex End
	return theUserManager;
}

/* cache Users from /etc/pure-ftpd/pureftp.passwd file */
-(void)cacheUsers
{
    
    [users removeAllObjects];
    User *user;
    
    /* Parsing users */
    NSMutableArray *pw_lines;
    NSEnumerator *lineEnum;
    NSString *entry; 
    NSMutableArray *userInfo;
    
    NSString *lines = [[NSString alloc] initWithContentsOfFile:PW_FILE];
    if (lines != nil)
    {
        pw_lines = [NSMutableArray arrayWithArray:[lines componentsSeparatedByString:@"\n"]];
        // Last object is empty, we remove it
        [pw_lines removeLastObject];
        
        lineEnum = [pw_lines objectEnumerator];        
        while (entry=[lineEnum nextObject])  
         {
            userInfo = [NSMutableArray arrayWithArray: [entry componentsSeparatedByString:@":"]];
            user = [User userWithInfo:userInfo];
            [users addObject:user];
        }
        
    }
    [lines release];
    userListUpdated = NO;
}

static void strip_lf(char *str)
{
    char *f;
    
    if (str == NULL) {
        return;
    }
    if ((f = strchr(str, '\r')) != NULL) {
        *f = 0;
    }    
    if ((f = strchr(str, '\n')) != NULL) {
        *f = 0;
    }
}

-(void)writePasswdFile
{
    User *user;
    NSEnumerator *userEnum = [users objectEnumerator];
    passwdFile=@"";
    userListUpdated = NO;
    
    FILE *fp;
    const char *dbfile, *file;
    char *index_dbfile;
    size_t sizeof_index_dbfile;
    char *data_dbfile;
    size_t sizeof_data_dbfile;
    char *s;
    PureDBW dbw;
    int ret = PW_ERROR_UNEXPECTED_ERROR;
    char line[LINE_MAX];
    
    NSString *userBWDL, *userBWUL, *userQS;

    if([users count]>=1)
    {
        while (user = [userEnum nextObject])
        {
            // Bit transfer limits convertions
            if ([[user bw_dl] intValue] != 0)
                userBWDL = [NSString stringWithFormat:@"%@", [NSNumber numberWithUnsignedLong:[[user bw_dl] intValue] * 1024]];
            else
                userBWDL = [NSString stringWithString:@""];
            if ([[user bw_ul] intValue] != 0)
                userBWUL = [NSString stringWithFormat:@"%@", [NSNumber numberWithUnsignedLong:[[user bw_ul] intValue] * 1024]];
            else
                userBWUL = [NSString stringWithString:@""];
            if ([[user quota_size] intValue] != 0)
                userQS = [NSString stringWithFormat:@"%@", [NSNumber numberWithUnsignedLong:[[user quota_size] intValue] * 1048576]];
            else
                userQS = [NSString stringWithString:@""];
            
            
            if ([self hasEnoughInfoForUser:user])
            {
		
		
                passwdFile = [passwdFile stringByAppendingFormat:@"%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@\n", 
                                [user login], [user pwd], [user uid], [user gid], [user gecos], [user home], 
                                userBWUL, userBWDL, /* Converted to KB */
		                [user ul_ratio], [user dl_ratio], [user per_user_max],
		                [user quota_files], userQS, /* Converted to MB */
                                [user allow_local_ip], [user deny_local_ip], [user allow_client_ip], [user deny_client_ip], 
                                [user time_restrictions]];
            }
        }
    }
    
    NSLog(@"Saving Virtual Users...");
    [passwdFile writeToFile:PW_FILE atomically:YES];
           
    dbfile = [PDB_FILE cString];
    file = [PW_FILE cString];
    
    if (file == NULL) {
        fprintf(stderr, "Missing passwd file\n");
        return;// PW_ERROR_MISSING_PASSWD_FILE;
    }    
    if ((fp = fopen(file, "r")) == NULL) {
        perror("Unable to open the passwd file");
        return;// PW_ERROR_MISSING_PASSWD_FILE;
    }
    sizeof_index_dbfile = strlen(dbfile) + sizeof NEWPASSWD_INDEX_SUFFIX;
    if ((index_dbfile = malloc(sizeof_index_dbfile)) == NULL) {
        fclose(fp);
        //no_mem();
    }
    sizeof_data_dbfile = strlen(dbfile) + sizeof NEWPASSWD_DATA_SUFFIX;
    if ((data_dbfile = malloc(sizeof_data_dbfile)) == NULL) {
        fclose(fp);
        free(index_dbfile);
        //no_mem();
    }
    snprintf(index_dbfile, sizeof_index_dbfile, "%s%s",
             dbfile, NEWPASSWD_INDEX_SUFFIX);
    snprintf(data_dbfile, sizeof_data_dbfile, "%s%s",
             dbfile, NEWPASSWD_DATA_SUFFIX);
    if (puredbw_open(&dbw, index_dbfile, data_dbfile, dbfile) != 0) {
        perror("Unable to create the database");
        goto err;
    }
    while (fgets(line, (int) sizeof line - 1U, fp) != NULL) {
        strip_lf(line);
        if (*line == PW_LINE_COMMENT) {
            continue;
        }
        if (*line == 0 || (s = strchr(line, *PW_LINE_SEP)) == NULL ||
            s[1] == 0) {
            continue;
        }
        *s++ = 0;
        if (puredbw_add_s(&dbw, line, s) != 0) {
            perror("Error while indexing a new entry");
            goto err;
        }
    }
    if (puredbw_close(&dbw) != 0) {
        perror("Unable to close the database");
    } else {
        ret = 0;
    }
    err:
    puredbw_free(&dbw);
    free(index_dbfile);
    free(data_dbfile);    
    fclose(fp);
    
    
}

-(BOOL) hasEnoughInfoForUser:(User *)user
{
    if ([[user login] isEqualToString:@""] || [[user pwd] isEqualToString:@""] || [[user home] isEqualToString:@""] ||
        [[user uid] isEqualToString:@""] || [[user gid] isEqualToString:@""] )
        return NO;
    
    else 
        return YES;
}

-(void) createNewUser
{   
    User *user;
    NSMutableArray *userInfo = [[NSMutableArray alloc] initWithCapacity:18];
   int i=0;
    
    for (i; i<=17; i++)
    {
        [userInfo addObject:@""];
    }
    
    //Set default User and Group ID
    NSString *uid = [NSString stringWithString:@"82"];
    NSString *gid = [NSString stringWithString:@"82"];
    
    [userInfo replaceObjectAtIndex:2 withObject:uid];
    [userInfo replaceObjectAtIndex:3 withObject:gid];
    [userInfo replaceObjectAtIndex:5 withObject:[[NSMutableDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile] objectForKey:PureFTPUserBaseDir]];

    
    user = [User userWithInfo:userInfo];
    [user setNewUser:YES];
    [users addObject:user];
    userListUpdated = YES;
}

-(void) saveAlert
{
    NSBeginAlertSheet(NSLocalizedString(@"Virtual Users have been modified",@"localized string"), 
                      NSLocalizedString(@"Save",@"localized string"), 
                      NSLocalizedString(@"Cancel",@"localized string"),  
                      NSLocalizedString(@"Don't Save",@"localized string"),
                      [NSApp mainWindow], self, @selector(sheetDidEnd:returnCode:contextInfo:), 
                      NULL, NULL, 
                      NSLocalizedString(@"Would you like to apply these changes to PureFTPd ?",@"localized string"),
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
        [self saveUsers];
        [pureController setSelectNow:YES];
    }
    else if (returnCode == NSAlertOtherReturn)
    {
        [self cacheUsers];
        [pureController setSelectNow:YES];
        [[pureController userTable] reloadData];
        if ([[pureController userTable] selectedRow] != -1)
            [pureController getUserInfoFor:[users objectAtIndex:0]];
    }
    else if (returnCode == NSAlertAlternateReturn)
    {
        [pureController setSelectNow:NO];
    }
    
    [NSApp stopModal];
}


-(void) saveUsers
{
    NSMutableArray *usersToSave = [[NSMutableArray alloc] init];
    
    NSEnumerator *usersEnum = [users objectEnumerator];
    User *user;
    while (user = [usersEnum nextObject])
    {
        if ([self hasEnoughInfoForUser:user])
        {
            if ([user hasBeenEdited])
            {
                [user setHasBeenEdited:NO];
                [user setNewUser:NO];
                // Generate encrypted password
                if([user pwdModified])
                {
                    [user setPwd:[user generatePwd]];
                    [user setPwdModified:NO];
                }
                [user setAllowClientIP:[allowedIP componentsJoinedByString:@","]];
                [user setDenyClientIP:[deniedIP componentsJoinedByString:@","]];
            }
         [usersToSave addObject:user];
        }
    }
    
    if(users)
        [users release];
    
    users = [[NSMutableArray alloc] initWithArray:usersToSave];
    [self writePasswdFile];
    
    [[pureController userTable] reloadData];
}

/* Return list of User objects */
-(NSMutableArray *) getUsers
{
    return users;
}

-(NSMutableArray *) allowedIP
{
    return allowedIP;
}

-(NSMutableArray *) deniedIP
{
    return deniedIP;
}

-(void)setAllowedIP:(NSMutableArray *) newAllowedIP
{
    if (allowedIP)
        [allowedIP release];
    allowedIP = [[NSMutableArray alloc] initWithArray:newAllowedIP];
}

-(void)setDeniedIP:(NSMutableArray *) newDeniedIP
{
    if (deniedIP)
        [deniedIP release];
    deniedIP = [[NSMutableArray alloc] initWithArray:newDeniedIP];
}




-(BOOL) isUserListUpdated
{
    return userListUpdated;
}

-(void)setUserListUpdated:(BOOL)flag
{
    userListUpdated=flag;
}


// userTable DataSource
- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
    if ([users count] == 0) // deactivate fields
        [pureController disableUserFields];
    else 
        [pureController enableUserFields];
    
    
    if ([tableView isEqualTo:[pureController userTable]])
        return [users count];
    else if ([tableView isEqualTo:[pureController allowClientTable]])
        return [allowedIP count];
    else if ([tableView isEqualTo:[pureController denyClientTable]])
        return [deniedIP count];

    // We should never reach this
    return 0;
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn *)col row:(int)row
{
    User *user = [users objectAtIndex:row];
    
    if ([tableView isEqualTo:[pureController userTable]]){
        
	if (user!= nil) {
		if ([user isNewUser])
                    {
                        return @"New User";
                    }
                else
                    return [user login];
	}
    }
    else if ([tableView isEqualTo:[pureController allowClientTable]]){
        return [allowedIP objectAtIndex:row];
    }
    else if ([tableView isEqualTo:[pureController denyClientTable]]){
        return [deniedIP objectAtIndex:row];
    }
    
    // We should never reach this
    return @"Not found";
}

// userTable delegates
- (BOOL)tableView:(NSTableView *)tableView shouldSelectRow:(int)row
{
    if ([tableView isEqualTo:[pureController userTable]])
    {
        User *user = [users objectAtIndex:[tableView selectedRow]];
        [pureController saveBanner];
        if ([self hasEnoughInfoForUser:user])
        {
            [pureController getUserInfoFor:[users objectAtIndex:row]];
        }
        else 
        {
            NSRunAlertPanel(NSLocalizedString(@"Incomplete user settings",@"localized string"), 
                            NSLocalizedString(@"Please specify at least a login, password, home directory, user and group id for this user.\n\nThis account won't be saved before you do so.",@"localized string"), 
                            NSLocalizedString(@"OK",@"localized string"), NULL, NULL);
            [pureController getUserInfoFor:[users objectAtIndex:row]];
            
        }
    }
    
    else if ([tableView isEqualTo:[pureController allowClientTable]]){
        [[pureController allowClientRemoveButton] setEnabled:YES];
    }
    
    else if ([tableView isEqualTo:[pureController denyClientTable]]){
        [[pureController denyClientRemoveButton] setEnabled:YES];
    }
    
    return YES;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    if ([[notification object] isEqualTo:[pureController allowClientTable]] &&
        ([[notification object] selectedRow] == -1))
        [[pureController allowClientRemoveButton] setEnabled:NO];
   else if ([[notification object] isEqualTo:[pureController denyClientTable]] &&
        ([[notification object] selectedRow] == -1))
        [[pureController denyClientRemoveButton] setEnabled:NO]; 
}

@end
