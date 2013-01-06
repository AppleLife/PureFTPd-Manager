//
//  FTPStats.h
//  PureFTP
//
//  Created by Jean-Matthieu on Sun Dec 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface FTPStats : NSObject {
    /* dict 
    {
	UserArray (keyInDict:username)
        {
	    connectionInfoDictionary;
	}
    }
    */
    NSMutableDictionary *statsDictionary;
}



// Stats for user
-(NSMutableArray *) statsForUser:(NSString *) aUser;
-(void) clearStatsForUser:(NSString *) aUser;

// Manage data dictionary
-(NSMutableDictionary *) statsDictionary;
-(void) clearStatsDictionary;
-(void) saveStatsDictionaryTo:(NSString *) aPath;

@end
