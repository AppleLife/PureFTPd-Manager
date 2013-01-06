//
//  MySQLUserManager.h
//  PureFTP
//
//  Created by Jean-Matthieu on Tue May 11 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SMySQL_bundled/SMySQL_bundled.h>
#import "VirtualUser.h"

@interface MySQLUserManager : NSObject {
    NSMutableDictionary *usersDictionary;
    NSDictionary *compareUsersDictionary;
    
    MCPConnection *mySQLConnection;
	BOOL cryptedPassword;
}

/* Get the singleton instance of this class */
+ (id)getInstance;

- (BOOL)cacheUsers;
- (BOOL)connect;
- (void)disconnect;

- (void)syncUsersDictionary;
- (void)createUser;
- (void)saveUser:(VirtualUser *) aUser;
- (void)deleteUser:(VirtualUser *) aUser;

- (BOOL) hasEnoughInfoForUser:(VirtualUser *)user;
- (NSMutableDictionary *)usersDictionary;
- (NSDictionary *)compareUsersDictionary;
- (void)setUsersDictionary:(NSMutableDictionary *)newUsersDictionary;
- (void)setCompareUsersDictionary:(NSDictionary *)newUsersDictionary;


@end
