//
//  UserStatsController.h
//  PureFTP
//
//  Created by Jean-Matthieu on Thu Jan 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "NSXLogParser.h"


#define  USERNAME @"Username"
#define  USERIP @"UserIP"
#define  DATE @"tc_date"
#define  TIME @"tc_time"
#define  TYPE @"tc_type"
#define  FILENAME @"tc_filename"
#define  FILESIZE @"tc_size"

#define CLF 0
#define W3C 1



@interface UserStatsController : NSObject {
    NSMutableDictionary *userStatsDict;
    NSNumber *lastLine;
    NSXLogParser *statsParser;
    NSNumber *logFormat;
}

-(NSMutableDictionary *) dictionary;
-(void) parseFile:(NSString *)aPath withPattern:(NSString *) aPattern;
-(void) orderCLFStats;
-(void) orderW3CStats;
-(void) orderUserStatsDict;


@end
