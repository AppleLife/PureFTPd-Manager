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

#import "User.h"

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <fcntl.h>

@implementation User

#pragma mark 
#pragma mark #--==> Initialization <==--#
+ (id)userWithInfo:(NSMutableArray *)userInfo
{
    User *user = [[User alloc] initWithInfo:userInfo];
    [user autorelease];
    return user;
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
        pwd = [[NSString alloc] initWithString:[userInfo objectAtIndex:1]];
        uid = [[NSString alloc] initWithString:[userInfo objectAtIndex:2]];
        gid = [[NSString alloc] initWithString:[userInfo objectAtIndex:3]];
        gecos = [[NSString alloc] initWithString:[userInfo objectAtIndex:4]];
        home = [[NSString alloc] initWithString:[userInfo objectAtIndex:5]];
        if ([bwul intValue]!=0)
	    bw_ul= [[NSString alloc] initWithFormat:@"%d", [bwul intValue]/1024];
	else 
	    bw_ul = [[NSString alloc] initWithString:@""];
	
	if ([bwdl intValue]!=0)
	    bw_dl = [[NSString alloc] initWithFormat:@"%d", [bwdl intValue]/1024];
	else
	    bw_dl = [[NSString alloc] initWithString:@""];
        
	ul_ratio = [[NSString alloc] initWithString:[userInfo objectAtIndex:8]];
        dl_ratio = [[NSString alloc] initWithString:[userInfo objectAtIndex:9]];
        per_user_max = [[NSString alloc] initWithString:[userInfo objectAtIndex:10]];
        quota_files = [[NSString alloc] initWithString:[userInfo objectAtIndex:11]];
	if([quotasize intValue] !=0)
	    quota_size  = [[NSString alloc] initWithFormat:@"%@", [NSNumber numberWithUnsignedLong:[quotasize doubleValue ]/1048576]];
        else
	    quota_size  = [[NSString alloc] initWithString:@""];
	
        if ( [[userInfo objectAtIndex:13] isEqualToString:@""] )
        {
             allow_local_ip= [[NSString alloc] initWithString:@""];
        }
        else 
             allow_local_ip = [[NSString alloc] initWithString:[userInfo objectAtIndex:13]];
        
        
        if ( [[userInfo objectAtIndex:14] isEqualToString:@""] )
        {
           deny_local_ip = [[NSString alloc] initWithString:@""];
        }
        else 
            deny_local_ip = [[NSString alloc] initWithString:[userInfo objectAtIndex:14]];
        
        
        if ( [[userInfo objectAtIndex:15] isEqualToString:@""] )
        {
            allow_client_ip = [[NSString alloc] initWithString:@""];
        }
        else 
        { 
            allow_client_ip = [[NSString alloc] initWithString:[userInfo objectAtIndex:15]];
        }
        
        if ( [[userInfo objectAtIndex:16] isEqualToString:@""] )
        {
            deny_client_ip = [[NSString alloc] initWithString:@""];
        }
        else 
        {
            deny_client_ip = [[NSString alloc] initWithString:[userInfo objectAtIndex:16]];
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

-(NSString *) generatePwd
{
    static const char crcars[64] =
        "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789./";
   
   
    NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/etc/pure-ftpd/pure-ftpd.plist"];
    if ([[prefs objectForKey:OSVersion] intValue] >= 0x1030)
    {
        // User is using Mac OS X 10.3.0
        /* Blowfish */
           
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

-(NSString *) allow_local_ip
{
    return allow_local_ip;
}

-(void) setAllowLocalIP:(NSString *)string
{
    [allow_local_ip autorelease];
    allow_local_ip = [string copy];
}

-(NSString *) deny_local_ip
{
    return deny_local_ip;
}

-(void) setDenyLocalIP:(NSString *)string
{
    [deny_local_ip autorelease];
    deny_local_ip = [string copy];
}

-(NSString *) allow_client_ip
{
    return allow_client_ip;
}

-(void) setAllowClientIP:(NSString *)string
{
    [allow_client_ip autorelease];
    allow_client_ip = [string copy];
}

-(NSString *) deny_client_ip
{
    return deny_client_ip;
}

-(void) setDenyClientIP:(NSString *)string
{
    [deny_client_ip autorelease];
    deny_client_ip = [string copy];
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


#pragma mark 
#pragma mark #--==> User flags <==--#

-(BOOL) isNewUser
{
    return isNewUser;
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

@end
