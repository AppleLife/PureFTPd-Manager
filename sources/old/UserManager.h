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

#import <Foundation/Foundation.h>
#import "User.h"
#import "PureController.h"

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

@class User, PureController;

@interface UserManager : NSObject {
    NSMutableArray *users;
    NSMutableArray *allowedIP;
    NSMutableArray *deniedIP;
    
    NSString *passwdFile;
    BOOL userListUpdated;
    
    PureController *pureController;
}

/* Get the singleton instance of this class */
+(id) getInstance;

/* cache Users from /etc/pure-ftpd/pureftp.passwd file */
-(void)cacheUsers;

/* Prepare the string that contains all users so it can written to pureftpd.passwd */
-(void)writePasswdFile;

/* Check if the mandatory info (account,  password, homedir, uid and gid) have been set */
-(BOOL) hasEnoughInfoForUser:(User *)user;

/* create a new user with empty userInfo */
-(void) createNewUser;


-(void) saveAlert;
-(void) saveUsers;

/* Return list of User objects */
-(NSMutableArray *) getUsers;
-(NSMutableArray *) allowedIP;
-(NSMutableArray *) deniedIP;
-(void)setAllowedIP:(NSMutableArray *) newAllowedIP;
-(void)setDeniedIP:(NSMutableArray *) newDeniedIP;

-(BOOL) isUserListUpdated;
-(void) setUserListUpdated:(BOOL)flag;

/* Virtual User Table Datasource */
- (int)numberOfRowsInTableView:(NSTableView*)tableView;
- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn *)col row:(int)row;
/* ... delegates */
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex;


@end
