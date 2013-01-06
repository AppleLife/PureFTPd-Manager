//
//  PureDBUserManager.h
//  PureFTP
//
//  Created by Jean-Matthieu on Fri Apr 30 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VirtualUser.h"
#import "defines.h"

#ifndef PW_FILE
#define PW_FILE @"/etc/pure-ftpd/pureftpd.passwd"
#endif

#ifndef PDB_FILE
#define PDB_FILE @"/etc/pure-ftpd/pureftpd.pdb"
#endif

#ifndef NEWPASSWD_INDEX_SUFFIX
#define NEWPASSWD_INDEX_SUFFIX ".index"
#endif

#ifndef NEWPASSWD_DATA_SUFFIX
#define NEWPASSWD_DATA_SUFFIX ".data"
#endif

#ifndef PW_LINE_COMMENT
# define PW_LINE_COMMENT '#'
#endif

#ifndef PW_LINE_SEP
#define PW_LINE_SEP ":"
#endif

#ifndef LINE_MAX
#define LINE_MAX 4096
#endif

#define PW_ERROR_UNEXPECTED_ERROR 0xff
#define PW_ERROR_MISSING_PASSWD_FILE (1 << 1)



@interface PureDBUserManager : NSObject {
    NSMutableDictionary *usersDictionary;
    NSDictionary *compareUsersDictionary;
    NSString *passwdData;
    
}

/* Get the singleton instance of this class */
+ (id)getInstance;

/* cache Users from /etc/pure-ftpd/pureftp.passwd file */
- (void)cacheUsers;

/* Prepare the string that contains all users so it can written to pureftpd.passwd */
- (BOOL) hasEnoughInfoForUser:(VirtualUser *)user;
- (void)writePasswdFile;



/* create a new user with empty userInfo */
- (void)createNewUser;

/* Get users from PureDBManager */
- (NSMutableDictionary *)usersDictionary;
- (NSDictionary *)compareUsersDictionary;
- (void)setUsersDictionary:(NSMutableDictionary *)newUsersDictionary;

@end
