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

//
#import "defines.h"
#import <Foundation/Foundation.h>


@interface User : NSObject {
    NSString *login;
    NSString *pwd;
    NSString *uid;
    NSString *gid;
    NSString *home;
    NSString *gecos;
    NSString *bw_dl; /*unsigned long*/
    NSString *bw_ul; /*unsigned long*/
//    int has_bw_dl;
//    int has_bw_ul;
    NSString *per_user_max; /*unsigned int*/
//    int has_per_user_max;
    NSString *quota_files; /*unsigned long long*/ 
    NSString *quota_size; /*unsigned long long*/   
//    int has_quota_files;
//    int has_quota_size;
    NSString *dl_ratio; /*unsigned int*/
    NSString *ul_ratio; /*unsigned int*/
//    int dl_ratio;
//    int ul_ratio;
    NSString *allow_local_ip;
    NSString *deny_local_ip;
    NSString *allow_client_ip;
    NSString *deny_client_ip;
    NSString *time_begin; /*unsigned int*/
    NSString *time_end; /*unsigned int*/
//    int has_time;

    BOOL isNewUser;
    BOOL hasBeenEdited;
    BOOL pwdModified;
}

+(id) userWithInfo:(NSMutableArray *)userInfo;
- (id)initWithInfo:(NSMutableArray *)userInfo;

-(NSString *)login;
-(void) setLogin:(NSString *)string;

-(NSString *) pwd; 
-(void) setPwd:(NSString *)string;
-(NSString *) generatePwd;

-(NSString *) uid;
-(void) setUid:(NSString *)string;

-(NSString *) gid;
-(void) setGid:(NSString *)string;

-(NSString *) gecos;
-(void) setGecos:(NSString *)string;

-(NSString *) home;
-(void) setHome:(NSString *)string;

-(NSString *) bw_ul;
-(void) setBw_ul:(NSString *)string;

-(NSString *) bw_dl;
-(void) setBw_dl:(NSString *)string;

-(NSString *) ul_ratio;
-(void) setUl_ratio:(NSString *)string;

-(NSString *) dl_ratio;
-(void) setDl_ratio:(NSString *)string;

-(NSString *) per_user_max;
-(void) setUserMax:(NSString *)string;

-(NSString *) quota_files;
-(void) setQuotaFiles:(NSString *)string;

-(NSString *) quota_size;
-(void) setQuotaSize:(NSString *)string;

-(NSString *) allow_local_ip;
-(void) setAllowLocalIP:(NSString *)string;

-(NSString *) deny_local_ip;
-(void) setDenyLocalIP:(NSString *)string;

-(NSString *) allow_client_ip;
-(void) setAllowClientIP:(NSString *)string;

-(NSString *) deny_client_ip;
-(void) setDenyClientIP:(NSString *)string;

-(NSString *) time_begin;
-(void) setTimeBegin:(NSString *)string;

-(NSString *) time_end;
-(void) setTimeEnd:(NSString *)string;

-(NSString *)time_restrictions;

-(BOOL) isNewUser;
-(void) setNewUser:(BOOL)flag;

-(BOOL) hasBeenEdited;
-(void) setHasBeenEdited:(BOOL)flag;

-(BOOL) pwdModified;
-(void) setPwdModified:(BOOL)flag;

@end
