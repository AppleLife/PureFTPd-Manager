//
//  FTPStats.m
//  PureFTP
//
//  Created by Jean-Matthieu on Sun Dec 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#import "FTPStats.h"
#import "defines.h"


@implementation FTPStats

-(id) init
{
    self = [super init];
    if (self)
    {
	if ([[NSFileManager defaultManager] fileExistsAtPath:PureFTPStatsFile])
	{
	    statsDictionary = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPStatsFile];
	} else {
	    statsDictionary = [[NSMutableDictionary alloc] init];
	}
	
	
	return self;
    }
    return nil;
}

-(void) dealloc
{
    [statsDictionary release];
}

#pragma mark 
#pragma mark -- statsForUser operations --
-(NSMutableArray *) statsForUser:(NSString *) aUser
{
    if ((aUser == nil) || [aUser isEqualToString:@""])
	return nil;
    else
	return [statsDictionary objectForKey:aUser];
}

-(void) clearStatsForUser:(NSString *) aUser
{
    if ((aUser == nil) || [aUser isEqualToString:@""])
	return;
    else
    {
	[statsDictionary removeObjectForKey:aUser];
    }
}

#pragma mark 
#pragma mark -- statsDictionary operations --
-(NSMutableDictionary *) statsDictionary
{
    return statsDictionary;
}

-(void) clearStatsDictionary
{
    [statsDictionary removeAllObjects];
}

-(void) saveStatsDictionaryTo:(NSString *) aPath

{
    if ((aPath == nil) || ([aPath isEqualToString:@""]))
    {
	[statsDictionary writeToFile:PureFTPStatsFile atomically:YES];
    }
    else 
    {
	[statsDictionary writeToFile:aPath atomically:YES];
    }
}
@end
