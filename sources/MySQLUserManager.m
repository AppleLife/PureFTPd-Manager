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


#import "MySQLUserManager.h"
#import <Cocoa/Cocoa.h>
#import "defines.h"

static MySQLUserManager *theMySQLUserManager = nil;

@implementation MySQLUserManager

/* Get the singleton instance of this class */
+(id) getInstance
{
    // TODO: Mutex Begin
    if (theMySQLUserManager == nil) {
        theMySQLUserManager = [[MySQLUserManager alloc] init];
    }
    // TODO: Mutex End
    return theMySQLUserManager;
}

- (id)init
{
    self = [super init];
    if (self) {
        usersDictionary = [[NSMutableDictionary alloc] init];
		cryptedPassword = NO;
    }
    return self;
}

- (void)dealloc
{
    if (mySQLConnection)
        [mySQLConnection release];
    
    [usersDictionary release];
    [super dealloc];
}

#pragma mark Database Connection
- (BOOL)cacheUsers 
{
    if(![self connect])
        return NO;
    [self syncUsersDictionary];
    return YES;
}

- (BOOL)connect
{
    if (mySQLConnection)
        [mySQLConnection release];
    
    // Get values from pureftpd prefs
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
    NSString *host = [preferences objectForKey:PureFTPMySQLHost];
    NSString *port = [preferences objectForKey:PureFTPMySQLPort];
    NSString *login = [preferences objectForKey:PureFTPMySQLUsername];
    NSString *password = [preferences objectForKey:PureFTPMySQLPassword];
    NSString *database = [preferences objectForKey:PureFTPMySQLDatabase];
    NSNumber *crypt = [preferences objectForKey:PureFTPMySQLCrypt];
	if ([crypt intValue]){
		cryptedPassword = YES;
	} else {
		cryptedPassword = NO;
	}
	
    mySQLConnection = [[MCPConnection alloc] initToHost:host withLogin:login password:password usingPort:[port intValue]];
  
        
    if (![mySQLConnection selectDB:database])
    {
        [mySQLConnection release];
        mySQLConnection = nil;
        return NO;
    }
   
    return YES;
}

- (void)disconnect
{
    [mySQLConnection disconnect];
}

- (void)syncUsersDictionary
{
    [usersDictionary removeAllObjects];
    NSArray *qResults;
    NSString *qString = @"select * from `users` order by `Login` asc";
    qResults = [mySQLConnection getAllRowsFromQuery:qString asType:MCPTypeDictionary];
    
    NSEnumerator *resultsEnum = [qResults objectEnumerator];
    id entry;
    while(entry = [resultsEnum nextObject]){

#define OBJECTISNULL(X) ([X isKindOfClass:[NSNull class]] ? @"" : ([X isKindOfClass:[NSString class]] ? X : [X stringValue]) )
        
        NSMutableArray *userInfo = [NSMutableArray arrayWithObjects:OBJECTISNULL([entry objectForKey:@"Login"]), 
            OBJECTISNULL([entry objectForKey:@"Password"]),
            OBJECTISNULL([entry objectForKey:@"Uid"]),
            OBJECTISNULL([entry objectForKey:@"Gid"]),
            // Fullname
            @"",
            OBJECTISNULL([entry objectForKey:@"Dir"]),
            OBJECTISNULL([entry objectForKey:@"ULBandwidth"]),
            OBJECTISNULL([entry objectForKey:@"DLBandWidth"]),
            OBJECTISNULL([entry objectForKey:@"ULRatio"]),
            OBJECTISNULL([entry objectForKey:@"DLRatio"]),
            // connection max
            @"",
            OBJECTISNULL([entry objectForKey:@"QuotaFiles"]),
            OBJECTISNULL([entry objectForKey:@"QuotaSize"]),
            // allow deny local
            @"", @"",
            // allow deny client
            @"", @"",
            // time restrictions, 
            @"",
            nil];
        
        VirtualUser *user = [VirtualUser userWithInfo:userInfo];
        [usersDictionary setObject:user forKey:[user login]];
    }
    
    [self setCompareUsersDictionary:usersDictionary];
}

#pragma mark Users queries


- (void)saveUser:(VirtualUser *) aUser
{
   
    NSNumber *ulbw, *dlbw, *quotasize;
    if ([[aUser bw_dl] intValue] != 0)
        ulbw = [NSNumber numberWithUnsignedLong:[[aUser bw_dl] intValue] * 1024];
    else
        ulbw = NULL;
    if ([[aUser bw_ul] intValue] != 0)
        dlbw = [NSNumber numberWithUnsignedLong:[[aUser bw_ul] intValue] * 1024];
    else
        dlbw = NULL;
    if ([[aUser quota_size] intValue] != 0)
        quotasize = [NSNumber numberWithUnsignedLong:[[aUser quota_size] intValue]];
    else
        quotasize = NULL;
        
    if ([self hasEnoughInfoForUser:aUser]){
        NSString *qString= nil;
        [aUser setHasBeenEdited:NO];
        
        if([aUser pwdModified])
        {
            [aUser setPwd:[aUser generatePwd:cryptedPassword]];
            [aUser setPwdModified:NO];
        }
        
        if([aUser isNewUser]){
            qString = [NSString stringWithFormat:@"INSERT INTO `users` (`Login`, `Password`, `Uid`, `Gid`, `Dir`, `ULBandwidth`, `DLBandWidth`, `ULRatio`, `DLRatio`,  `QuotaFiles`, `QuotaSize`) VALUES (\"%@\", \"%@\", %d, %d, \"%@\", %@, %@, %d, %d, %d, %@)", 
                [aUser login], [aUser pwd], [[aUser uid] intValue], [[aUser gid] intValue], [aUser home], ulbw, dlbw, [[aUser ul_ratio] intValue],
                [[aUser dl_ratio] intValue], [[aUser quota_files] intValue], quotasize];
            [aUser setNewUser:NO];
        } else {
            qString = [NSString stringWithFormat:@"UPDATE `users` SET `Password`=\"%@\", `Uid`=%d, `Gid`=%d, `Dir`=\"%@\", `ULBandwidth`=%@, `DLBandWidth`=%@, `ULRatio`=%d, `DLRatio`=%d, `QuotaFiles`=%d, `QuotaSize`=%@  where `Login` like \"%@\"",
                [aUser pwd], [[aUser uid] intValue], [[aUser gid] intValue], [aUser home], ulbw, dlbw, [[aUser ul_ratio] intValue], 
                [[aUser dl_ratio] intValue], [[aUser quota_files] intValue], quotasize, [aUser login]];
        }
        [mySQLConnection queryString:qString];
        
        if([aUser bannerModified])
        {
            [aUser saveBanner];
        }
    }
    
    [self syncUsersDictionary];
}

- (void)deleteUser:(VirtualUser *) aUser
{
    NSString *qString = [NSString stringWithFormat:@"DELETE from `users` where `Login` like \"%@\"", [aUser login]];
    [mySQLConnection queryString:qString];
    [self syncUsersDictionary];
}


#pragma mark Users utility functions
- (void)createUser
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
    
    for (i=0; i<=17; i++){
        [userInfo addObject:@""];
    }
    
    [userInfo replaceObjectAtIndex:0 withObject:NSLocalizedString(@"New User", @"New User")];
    
    
    //Set default User and Group ID
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

- (BOOL)hasEnoughInfoForUser:(VirtualUser *)user
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

- (void)setCompareUsersDictionary:(NSDictionary *)newUsersDictionary
{
    if(compareUsersDictionary)
        [compareUsersDictionary release];
    compareUsersDictionary = [[NSDictionary alloc] initWithDictionary:newUsersDictionary];
}


@end
