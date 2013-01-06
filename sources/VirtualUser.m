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


#import "VirtualUser.h"
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/types.h>
#include <pwd.h>
#include <grp.h>

#import "NSFileManager+ASExtensions.h"


@implementation VirtualUser
#pragma mark 
#pragma mark #--==> Initialization <==--#
+ (id)userWithInfo:(NSMutableArray *)userInfo
{
    VirtualUser *user = [[VirtualUser alloc] initWithInfo:userInfo];
    [user autorelease];
    return user;
}

- (id)copyWithZone:(NSZone *)zone
{
    NSMutableArray *userInfo = [[NSMutableArray alloc] initWithObjects:[self login], [self pwd],
        [self uid], [self gid], [self gecos], [self home], 
        [self bw_ul], [self bw_dl],
        [self ul_ratio], [self dl_ratio], [self per_user_max],
        [self quota_files], [self quota_size],
        [[self allow_local_ip] componentsJoinedByString:@","], [[self deny_local_ip] componentsJoinedByString:@","], 
        [[self allow_client_ip] componentsJoinedByString:@","], [[self deny_client_ip] componentsJoinedByString:@","], 
        [self time_restrictions], nil];
    
    VirtualUser *copy = [[[self class] allocWithZone: zone] 
            initWithInfo:userInfo];
    
    [copy setBanner:[self banner]];
    [userInfo release];
    return copy;
}



- (id)initWithInfo:(NSMutableArray *)userInfo
{
    NSMutableArray *timeArray;
    
    self = [super init];
    if(self)
    {
        NSString *bwul = [NSString stringWithString:[userInfo objectAtIndex:6]];
	NSString *bwdl = [NSString stringWithString:[userInfo objectAtIndex:7]];
	NSString *quotasize = [NSString stringWithString:[userInfo objectAtIndex:12]];
	
        login = [[NSString alloc] initWithString:[userInfo objectAtIndex:0]];
		if ([[NSString stringWithFormat:@"%c", [login characterAtIndex:0]] isEqualToString:@"#"]){
			[login release];
			login = [[NSString alloc] initWithString:[[userInfo objectAtIndex:0] substringFromIndex:1]];
			activated=NO;
		} else {
			activated=YES;
		}
        pwd = [[NSString alloc] initWithString:[userInfo objectAtIndex:1]];
        uid = [[NSString alloc] initWithString:[userInfo objectAtIndex:2]];
        gid = [[NSString alloc] initWithString:[userInfo objectAtIndex:3]];
        gecos = [[NSString alloc] initWithString:[userInfo objectAtIndex:4]];
        home = [[NSString alloc] initWithString:[userInfo objectAtIndex:5]];
        if ([bwul intValue]!=0)
	    bw_ul= [[NSString alloc] initWithFormat:@"%d", [bwul intValue]/1024];
	else 
	    bw_ul = [[NSString alloc] initWithString:@""];
	
	if ([bwdl doubleValue]!=0)
	    bw_dl = [[NSString alloc] initWithFormat:@"%d", [bwdl intValue]/1024];
	else
	    bw_dl = [[NSString alloc] initWithString:@""];
        
	ul_ratio = [[NSString alloc] initWithString:[userInfo objectAtIndex:8]];
        dl_ratio = [[NSString alloc] initWithString:[userInfo objectAtIndex:9]];
        per_user_max = [[NSString alloc] initWithString:[userInfo objectAtIndex:10]];
        quota_files = [[NSString alloc] initWithString:[userInfo objectAtIndex:11]];
	if([quotasize intValue] !=0){
	    quota_size  = [[NSString alloc] initWithFormat:@"%@", [NSNumber numberWithUnsignedLong:[quotasize intValue]]];
	} else {
	    quota_size  = [[NSString alloc] initWithString:@""];
	}
	
	NSArray *testArray = [[userInfo objectAtIndex:13] componentsSeparatedByString:@","];
	if (([testArray count] == 0) || ([[userInfo objectAtIndex:13] isEqualToString:@""]))
	{
	    allow_local_ip= [[NSMutableArray alloc] init];
	} else {
	    allow_local_ip = [[NSMutableArray alloc] initWithArray:testArray];
	}
	
	testArray = [[userInfo objectAtIndex:14] componentsSeparatedByString:@","];
	if (([testArray count] == 0) || ([[userInfo objectAtIndex:14] isEqualToString:@""]))
	{
	    deny_local_ip= [[NSMutableArray alloc] init];
	} else {
	    deny_local_ip = [[NSMutableArray alloc] initWithArray:testArray];
	}
	
	testArray = [[userInfo objectAtIndex:15] componentsSeparatedByString:@","];
	if (([testArray count] == 0) || ([[userInfo objectAtIndex:15] isEqualToString:@""]))
	{
	    allow_client_ip= [[NSMutableArray alloc] init];
	} else {
	    allow_client_ip = [[NSMutableArray alloc] initWithArray:testArray];
	}
	
	testArray = [[userInfo objectAtIndex:16] componentsSeparatedByString:@","];
	if (([testArray count] == 0) || ([[userInfo objectAtIndex:16] isEqualToString:@""]))
	{
	    deny_client_ip= [[NSMutableArray alloc] init];
        } else {
	    deny_client_ip = [[NSMutableArray alloc] initWithArray:testArray];
	}
	
	if ( [[userInfo objectAtIndex:17] isEqualToString:@""] )
        {
            time_begin = [[NSString alloc] initWithString:@""];
            time_end = [[NSString alloc] initWithString:@""];
        }
        else 
        {
            timeArray = [NSMutableArray arrayWithArray:[[userInfo objectAtIndex:17] componentsSeparatedByString:@"-"]];
            time_begin = [[NSString alloc] initWithString:[timeArray objectAtIndex:0]]; /*unsigned int*/
            time_end = [[NSString alloc] initWithString:[timeArray objectAtIndex:1]]; /*unsigned int*/
        }
        
        // Load the banner 
        bannerModified = NO;
        NSString *bannerPath = [home stringByAppendingPathComponent:@".banner"];
        if ([[NSFileManager defaultManager] fileExistsAtPath:bannerPath]){
            banner = [[NSString alloc] initWithContentsOfFile:bannerPath];
        } else {
            banner = [[NSString alloc] initWithString:@""];
        }
        
    }
    
    return self;
}

-(void) dealloc
{
    [login release];
    [pwd release];
    [uid release];
    [gid release];
    [gecos release];
    [home release];
    [bw_ul release];
    [bw_dl release];
    [ul_ratio release];
    [dl_ratio release];
    [per_user_max release];
    [quota_files release];
    [quota_size release];
    [allow_local_ip release];
    [deny_local_ip release];
    [allow_client_ip release];
    [deny_client_ip release];
    [time_begin release];
    [time_end release];
    [banner release];
    [super dealloc];
}

#pragma mark 
#pragma mark #--==> Accessing / Setting members <==--#
-(NSString *) login
{
    return login;
}

-(void) setLogin:(NSString *)string
{
    [login autorelease];
    login = [string copy];
}


-(NSString *) pwd 
{
    return pwd;
}

-(void) setPwd:(NSString *)string
{
    [pwd autorelease];
    pwd = [string copy];
    pwdModified=YES;
}

// from pure-pw.c
static unsigned int pw_zrand(void)                                                                                                          
{                                                                                                                                           
    int fd;                                                                                                                                 
    int ret;                                                                                                                                
    
    if ( ((fd = open("/dev/urandom", O_RDONLY | O_NONBLOCK)) == -1) ) 
    {
nax:
        return (unsigned int) random();
    }
    
    if (read(fd, &ret, sizeof ret) != (ssize_t) sizeof ret) {
        close(fd);
        goto nax;
    }
    close(fd);
    return (unsigned int) ret;                                                                                                              
}

-(NSString *) generatePwd:(BOOL)crted
{
	if (!crted)
		return [NSString stringWithString:pwd];
	
    static const char crcars[64] =
    "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789./";
    register const char *crypted;
	register char *result;
	const char * passwd = [pwd cString];
	 if ((crypted = (const char *)      /* Blowfish */
         crypt("test", "$2a$07$1234567890123456789012")) != NULL &&        
        strcmp(crypted, "$2a$07$123456789012345678901uKO4"
               "/IReKqBzRzT6YaajGvw20UBdHW7m") == 0) {
        char salt[] = "$2a$07$0000000000000000000000";        
        int c = 28;
        
        do {            
            c--;
            salt[c] = crcars[pw_zrand() & 63];
        } while (c > 7);
        //NSLog(@"Using Blowfish");
        result = (char *) crypt(passwd, salt);        
    } else if ((crypted = (const char *)    /* MD5 */
                crypt("test", "$1$12345678$")) != NULL &&
               strcmp(crypted, "$1$12345678$oEitTZYQtRHfNGmsFvTBA/") == 0) {
        char salt[] = "$1$00000000";
        int c = 10;
        
        do {            
            c--;
            salt[c] = crcars[pw_zrand() & 63];
        } while (c > 3);
		//NSLog(@"Using MD5");
        result = (char *) crypt(passwd, salt);
    } else if ((crypted = (const char *)    /* Extended DES */
                crypt("test", "_.../1234")) != NULL &&
               strcmp(crypted, "_.../1234PAPUVmqGzpU") == 0) {
        char salt[] = "_.../0000";
        int c = 8;
        
        do {
            c--;
            salt[c] = crcars[pw_zrand() & 63];
        } while (c > 5);
		//NSLog(@"Using Extended DES");
        result = (char *) crypt(passwd, salt);
    }
    /* Simple DES */
    else {
        char salt[] = "00";
        
        salt[0] = crcars[pw_zrand() & 63];
        salt[1] = crcars[pw_zrand() & 63];
		//NSLog(@"Using DES");
        result = (char *) crypt(passwd, salt);        
    }
	
	 return [NSString stringWithFormat:@"%s", (char *) result]; 
	
    /*
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/etc/pure-ftpd/pure-ftpd.plist"];
    if ([[prefs objectForKey:OSVersion] intValue] >= 0x1030)
    {
        // User is using Mac OS X 10.3.0
        // Blowfish 
        
        char salt[] = "$2a$07$0000000000000000000000";        
        int c = 28;
        
        do {            
            c--;
            salt[c] = crcars[pw_zrand() & 63];
        } while (c > 7);
        
        return [NSString stringWithFormat:@"%s", (char *) crypt([pwd cString], salt)];        
    }
    else
    {
        char salt[]="00";
        salt[0] = crcars[pw_zrand() & 63];
        salt[1] = crcars[pw_zrand() & 63];
        
        return [NSString stringWithFormat:@"%s", (char *) crypt([pwd cString], salt)];  
    }
	*/
}


-(NSString *) uid
{
    return uid;
}

-(void) setUid:(NSString *)string
{
    [uid autorelease];
    uid = [string copy];
}

-(NSString *) gid
{
    return gid;
}

-(void) setGid:(NSString *)string
{
    [gid autorelease];
    gid = [string copy];
}


-(NSString *) gecos
{
    return gecos;
}

-(void) setGecos:(NSString *)string
{
    [gecos autorelease];
    gecos = [string copy];
}

-(NSString *) home
{
    return home;
}

-(void) setHome:(NSString *)string
{
    [home autorelease];
    home = [string copy];
}


-(NSString *) bw_ul
{
    return bw_ul;
}

-(void) setBw_ul:(NSString *)string
{
    [bw_ul autorelease];
    bw_ul = [string copy];
}


-(NSString *) bw_dl
{
    return bw_dl;
}

-(void) setBw_dl:(NSString *)string
{
    [bw_dl autorelease];
    bw_dl = [string copy];
}


-(NSString *) ul_ratio
{
    return ul_ratio;
}

-(void) setUl_ratio:(NSString *)string
{
    [ul_ratio autorelease];
    ul_ratio = [string copy];
}

-(NSString *) dl_ratio
{
    return dl_ratio;
}

-(void) setDl_ratio:(NSString *)string
{
    [dl_ratio autorelease];
    dl_ratio = [string copy];
}

-(NSString *) per_user_max
{
    return per_user_max;
}

-(void) setUserMax:(NSString *)string
{
    [per_user_max autorelease];
    per_user_max = [string copy];
}


-(NSString *) quota_files
{
    return quota_files;
}

-(void) setQuotaFiles:(NSString *)string
{
    [quota_files autorelease];
    quota_files = [string copy];
}

-(NSString *) quota_size
{
    return quota_size;
}

-(void) setQuotaSize:(NSString *)string
{
    [quota_size autorelease];
    quota_size = [string copy];
}

-(NSMutableArray *) allow_local_ip
{
    return allow_local_ip;
}

-(void) setAllowLocalIP:(NSMutableArray *)anArray
{
    [allow_local_ip autorelease];
    allow_local_ip = [anArray copy];
}

-(NSMutableArray *) deny_local_ip
{
    return deny_local_ip;
}

-(void) setDenyLocalIP:(NSMutableArray *)anArray
{
    [deny_local_ip autorelease];
    deny_local_ip = [anArray copy];
}

-(NSMutableArray *) allow_client_ip
{
    return allow_client_ip;
}

-(void) setAllowClientIP:(NSMutableArray *)anArray
{
    [allow_client_ip autorelease];
    allow_client_ip = [anArray copy];
}

-(NSMutableArray *) deny_client_ip
{
    return deny_client_ip;
}

-(void) setDenyClientIP:(NSMutableArray *)anArray
{
    [deny_client_ip autorelease];
    deny_client_ip = [anArray copy];
}

-(NSString *) time_begin
{
    return time_begin;
}

-(void) setTimeBegin:(NSString *)string
{
    [time_begin autorelease];
    time_begin = [string copy];
}

-(NSString *) time_end
{
    return time_end;
}

-(void) setTimeEnd:(NSString *)string
{
    [time_end autorelease];
    time_end = [string copy];
}

-(NSString *)time_restrictions
{
    if([time_begin isEqualToString:@""] || [time_end isEqualToString:@""])
        return @"";
    else 
        return [NSString stringWithFormat:@"%@-%@", time_begin, time_end];
}

-(NSString *)banner
{
    return banner;
}

-(void) setBanner:(NSString*) newBanner
{
    [banner autorelease];
    banner = [newBanner copy];
    
    bannerModified=YES;
}


-(BOOL) bannerModified
{
    return bannerModified;
}
-(void) saveBanner
{   
    NSString *bannerPath;
    NSString *_home = home;
    if ([[home lastPathComponent] isEqualToString:@"."])
        _home = [home stringByDeletingLastPathComponent];
      
    bannerPath = [_home stringByAppendingPathComponent:@".banner"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    struct passwd *userInfo;
    struct group *groupInfo;
    
    
    if (![fm fileExistsAtPath:_home] ){
        userInfo = getpwuid([uid intValue]);
        groupInfo = getgrgid([gid intValue]);
		
		if (userInfo == NULL)
			userInfo = getpwnam("nobody");
		if (groupInfo == NULL)
			groupInfo = getgrnam("nobody");
		
        NSString *username = [NSString stringWithCString:userInfo->pw_name];
        NSString *group = [NSString stringWithCString:groupInfo->gr_name];
        
        NSNumber *permissions = [NSNumber numberWithInt:0755];
        NSArray *objects = [NSArray arrayWithObjects:permissions, username,  group, nil];
        NSArray *keys = [NSArray arrayWithObjects:NSFilePosixPermissions, NSFileOwnerAccountName, NSFileGroupOwnerAccountName, nil];
        NSDictionary *posixAttributes = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
        NSDictionary *rootPosixAttrs = [NSDictionary dictionaryWithObject:permissions forKey:NSFilePosixPermissions];
        if (![fm createDirectoryAtPath:[_home stringByDeletingLastPathComponent] attributes:rootPosixAttrs recursive:YES])
            return;
        else {
            [fm createDirectoryAtPath:_home attributes:posixAttributes];
        }
        
    }
    
    if ([banner isEqualToString:@""]){
        [fm removeFileAtPath:bannerPath handler:nil];
    }
    
    [banner writeToFile:bannerPath atomically:NO];
    bannerModified=NO;
}


#pragma mark 
#pragma mark #--==> User flags <==--#

-(BOOL) isNewUser
{
    return isNewUser ;
}

-(void) setNewUser:(BOOL)flag
{
    isNewUser=flag;
}


-(BOOL) hasBeenEdited
{
    return hasBeenEdited;
}

-(void) setHasBeenEdited:(BOOL)flag
{
    hasBeenEdited=flag;
}

-(BOOL) pwdModified
{
    return pwdModified;
}
-(void) setPwdModified:(BOOL)flag
{
    pwdModified=flag;
}

- (BOOL)isActivated
{
	return activated;
}
- (void)setIsActivated:(BOOL)flag
{
	activated=flag;
}

@end
