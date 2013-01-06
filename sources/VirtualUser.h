//
//  VirtualUser.h
//  PureFTP
//
//  Created by Jean-Matthieu on Fri Apr 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "defines.h"

@interface VirtualUser : NSObject {
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
    NSMutableArray *allow_local_ip;
    NSMutableArray *deny_local_ip;
    NSMutableArray *allow_client_ip;
    NSMutableArray *deny_client_ip;
    NSString *time_begin; /*unsigned int*/
    NSString *time_end; /*unsigned int*/
    //    int has_time;
    
    NSString *banner;
    BOOL bannerModified;
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
-(NSString *) generatePwd:(BOOL)crypted;

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

-(NSMutableArray *) allow_local_ip;
-(void) setAllowLocalIP:(NSMutableArray *)anArray;

-(NSMutableArray *) deny_local_ip;
-(void) setDenyLocalIP:(NSMutableArray *)anArray;

-(NSMutableArray *) allow_client_ip;
-(void) setAllowClientIP:(NSMutableArray *)anArray;

-(NSMutableArray *) deny_client_ip;
-(void) setDenyClientIP:(NSMutableArray *)anArray;

-(NSString *) time_begin;
-(void) setTimeBegin:(NSString *)string;

-(NSString *) time_end;
-(void) setTimeEnd:(NSString *)string;

-(NSString *)time_restrictions;

-(NSString *)banner;
-(void) setBanner:(NSString*) newBanner;
-(BOOL) bannerModified;
-(void) saveBanner;

-(BOOL) isNewUser;
-(void) setNewUser:(BOOL)flag;

-(BOOL) hasBeenEdited;
-(void) setHasBeenEdited:(BOOL)flag;

-(BOOL) pwdModified;
-(void) setPwdModified:(BOOL)flag;



@end
