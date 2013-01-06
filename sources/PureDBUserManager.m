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


#import "PureDBUserManager.h"
#include <puredb_write.h>
#import <Cocoa/Cocoa.h>

static PureDBUserManager *thePureDBUserManager = nil;

@implementation PureDBUserManager

/* Get the singleton instance of this class */
+(id) getInstance
{
    // TODO: Mutex Begin
    if (thePureDBUserManager == nil) {
        thePureDBUserManager = [[PureDBUserManager alloc] init];
    }
    // TODO: Mutex End
    return thePureDBUserManager;
}


- (id)init
{
    self = [super init];
    if (self) {
        usersDictionary = [[NSMutableDictionary alloc] init];
        passwdData = [[NSString alloc] init];

        [self cacheUsers];
    }
    return self;
}

- (void)dealloc
{
    [usersDictionary release];
    [passwdData release];
    [super dealloc];
}

/* cache Users from /etc/pure-ftpd/pureftp.passwd file */
-(void)cacheUsers
{
    //[usersDictionary removeAllObjects];
    VirtualUser *user;
    NSMutableDictionary *aDict = [[NSMutableDictionary alloc] init];
    
    /* Parsing users */
    NSMutableArray *pw_lines;
    NSEnumerator *lineEnum;
    NSString *entry; 
    NSMutableArray *userInfo;
    
    NSString *lines = [NSString stringWithContentsOfFile:PW_FILE];
    if (lines != nil)
    {
        pw_lines = [NSMutableArray arrayWithArray:[lines componentsSeparatedByString:@"\n"]];
        // Last object is empty, we remove it
        [pw_lines removeLastObject];
        
        lineEnum = [pw_lines objectEnumerator];        
        while (entry=[lineEnum nextObject])  
        {
            userInfo = [NSMutableArray arrayWithArray: [entry componentsSeparatedByString:@":"]];
			NSString *quotaSize = [NSString stringWithFormat:@"%@",
						[NSNumber numberWithInt:([[NSString stringWithString:[userInfo objectAtIndex:12]] intValue] / 1048576)]];
			[userInfo replaceObjectAtIndex:12 withObject:quotaSize];
            user = [[VirtualUser alloc] initWithInfo:userInfo];
            [aDict setObject:user forKey:[user login]];
            [user release];
        }
        
    }
    [self setUsersDictionary:aDict];
    [aDict release];
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

- (BOOL) hasEnoughInfoForUser:(VirtualUser *)user
{
    if ([[user login] isEqualToString:@""] || [[user pwd] isEqualToString:@""] || [[user home] isEqualToString:@""] ||
        [[user uid] isEqualToString:@""] || [[user gid] isEqualToString:@""] ){
        NSRunAlertPanel(NSLocalizedString(@"Incomplete User Information",@"localized string"), 
                        NSLocalizedString(@"A new user account needs a login, a password and a home directory to be set before it can be saved.\nPlease complete this user informations.",@"localized string"), 
                        NSLocalizedString(@"OK",@"OK"), NULL, NULL);
        return NO;
    } else if([user isNewUser]) {
        NSEnumerator *usersDictionaryEnum = [compareUsersDictionary objectEnumerator];
        VirtualUser *existingUser;
        
        while (existingUser = [usersDictionaryEnum nextObject])
        {
            if ([[user login] isEqualToString:[existingUser login]]){
                NSString *format, *string;
                format = NSLocalizedString(@"%@ already exists on your system, please specify another username.", @"-username- already exists on your system, please specify another username.");
                string = [NSString stringWithFormat:format, [user login]];
                NSRunAlertPanel(NSLocalizedString(@"Duplicated Account !",@"Duplicated Account !"), 
                                string, 
                                NSLocalizedString(@"OK",@"OK"), NULL, NULL);
                return NO;
            }
        }
    }
    
    return YES;
}

-(void)writePasswdFile
{
    VirtualUser *user;
    NSEnumerator *usersDictionaryEnum = [usersDictionary objectEnumerator];
    NSMutableDictionary *newDictionary = [[NSMutableDictionary alloc] init];
    passwdData=@"";

    
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
    
    id userBWDL, userBWUL, userQS;
    
    if([usersDictionary count]>=1)
    {
        while (user = [usersDictionaryEnum nextObject])
        {
            if ([self hasEnoughInfoForUser:user]){
                [user setHasBeenEdited:NO];
                [user setNewUser:NO];
                // Generate encrypted password
                if([user pwdModified])
                {
					BOOL cryptedPassword = YES;
                    [user setPwd:[user generatePwd:cryptedPassword]];
                    [user setPwdModified:NO];
                }
                
                if([user bannerModified])
                {
                    [user saveBanner];
                }
                
                // Bit transfer limits convertions
                if ([[user bw_dl] intValue] != 0)
                    userBWDL = [NSNumber numberWithDouble:[[user bw_dl] intValue] * 1024];
                else
                    userBWDL = [NSString stringWithString:@""];
                if ([[user bw_ul] intValue] != 0)
                    userBWUL = [NSNumber numberWithDouble:[[user bw_ul] intValue] * 1024];
                else
                    userBWUL = [NSString stringWithString:@""];
                if ([[user quota_size] intValue] != 0){
                    userQS = [NSNumber numberWithDouble:[[user quota_size] doubleValue] * 1048576];
                    //NSLog(@"%@", userQS );
                }
                    
                else{
                    userQS = [NSString stringWithString:@""];}
		
				NSString *login=nil;
				if ([user isActivated])
				{
					login = [user login];
				} else {
					login = [NSString stringWithFormat:@"#%@",[user login]]; 
				}
				
                passwdData = [passwdData stringByAppendingFormat:@"%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@:%@\n", 
                    login, [user pwd], [user uid], [user gid], [user gecos], [user home], 
                    userBWUL, userBWDL, /* Converted to KB */
                    [user ul_ratio], [user dl_ratio], [user per_user_max],
                    [user quota_files], userQS, /* Converted to MB */
                    [[user allow_local_ip] componentsJoinedByString:@","], [[user deny_local_ip] componentsJoinedByString:@","], 
                    [[user allow_client_ip] componentsJoinedByString:@","], [[user deny_client_ip] componentsJoinedByString:@","], 
                    [user time_restrictions]];
                [newDictionary setObject:user forKey:[user login]];
            }
        }
    }
    
    [self setUsersDictionary:newDictionary];
    [newDictionary release];
    
    //NSLog(@"Saving PureDB Virtual Users...");
    [passwdData writeToFile:PW_FILE atomically:YES];
    
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

-(void) createNewUser
{   
    if ([usersDictionary objectForKey:NSLocalizedString(@"New User", @"New User")]){
        NSRunAlertPanel(NSLocalizedString(@"You can't to create a new user !",@"You can't to create a new user !"), 
                        NSLocalizedString(@"A new account creation is already in progress. Please complete it before adding another account.",@"A new account creation is already in progress. Please complete it before adding another account."), 
                        NSLocalizedString(@"OK",@"OK"), NULL, NULL);
        return;
    }
    
    VirtualUser *user;
    NSMutableArray *userInfo = [[NSMutableArray alloc] initWithCapacity:18];
    int i=0;
    [userInfo addObject:NSLocalizedString(@"New User", @"New User")];
   
    for (i=1; i<=17; i++){
        [userInfo addObject:@""];
    }
    

    
    
    //Set default User and Group ID
    //NSString *uid = [NSString stringWithString:@"82"];
    //NSString *gid = [NSString stringWithString:@"82"];
    
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
    NSString *uid = [NSString stringWithFormat:@"%@",[prefs objectForKey:@"PureFTPVirtualUID"]];
    NSString *gid = [NSString stringWithFormat:@"%@",[prefs objectForKey:@"PureFTPVirtualGID"]];
	
    [userInfo replaceObjectAtIndex:2 withObject:uid];
    [userInfo replaceObjectAtIndex:3 withObject:gid];
    [userInfo replaceObjectAtIndex:5 withObject:[[NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile] objectForKey:PureFTPUserBaseDir]];
    
    
    user = [VirtualUser userWithInfo:userInfo];
    [user setNewUser:YES];
    [user setBanner:@""];
    
    [usersDictionary setObject:user forKey:[user login]];
    [userInfo release];
}



- (NSMutableDictionary *)usersDictionary
{
    return usersDictionary;
}

- (NSDictionary *)compareUsersDictionary
{
    return compareUsersDictionary;
}

- (void)setUsersDictionary:(NSMutableDictionary *)newUsersDictionary
{
    if(usersDictionary)
        [usersDictionary release];
    usersDictionary = [[NSMutableDictionary alloc] initWithDictionary:newUsersDictionary];
   
    if(compareUsersDictionary)
        [compareUsersDictionary release];
    compareUsersDictionary = [[NSDictionary alloc] initWithDictionary:newUsersDictionary];

}


@end
