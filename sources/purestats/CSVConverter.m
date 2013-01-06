//
//  CSVConverter.m
//  PureFTP
//
//  Created by Jean-Matthieu Schaffhauser on 14/03/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "CSVConverter.h"
#import "UserStatsController.h"

@implementation CSVConverter
- (id)init
{
    self = [super init];
    if(self)
    {
        currentUser = nil;
        if (geteuid()==0)
            [self updateFTPStats];
        FTPStats = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/log/FTPStats.plist"];
        webpages = [[NSMutableDictionary alloc] init];
        return self;
    }
    
    return nil;
}

- (void) dealloc
{
    [FTPStats release];
    [webpages release];
    [super dealloc];
}

- (void)updateFTPStats
{
    
    NSDictionary *preferences = nil;
    if (nil != (preferences = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile]))
    {
            
        NSString *logPath = [preferences objectForKey:PureFTPLogLocation];
        NSString *logFormat = [preferences objectForKey:PureFTPLogFormat];
        NSString *pattern = nil;
        if ([logFormat isEqualToString:@"CLF"])
            pattern = [NSString stringWithString:CLF_PATTERN];
        else if ([logFormat isEqualToString:@"W3C"])
            pattern = [NSString stringWithString:W3C_PATTERN];
        
        UserStatsController *myUserStats = [[UserStatsController alloc] init];
        [myUserStats parseFile:logPath withPattern: pattern];
      
        [myUserStats release];
    }    
    
   
}

- (void) convertToCSV
{
    NSArray *users = [FTPStats allKeys];
    NSEnumerator *userEnum = [users objectEnumerator];
    NSString *aUser = nil;
    while ((aUser = [userEnum nextObject])!= nil)
    {
        id userDict = [FTPStats objectForKey:aUser];
        if ([userDict isKindOfClass:[NSArray class]]){
            currentUser = aUser;
            [self createUserStats:userDict];
        }
    }
}

- (void)createUserStats:(NSArray *)userStats
{
    NSString *CSVHeader = [NSString stringWithFormat:@"User, Host, Date, Type, Filename, Size"];
    NSMutableString *CSVContent = [[NSMutableString alloc] init];
    
    int numOfentries=[userStats count];
	int i=1;
	for (i=1; i<numOfentries; i++)
	{
		NSDictionary *entry=[userStats objectAtIndex:i];
		NSCalendarDate *date = [NSCalendarDate dateWithString:[[entry objectForKey:@"tc_date"]description] calendarFormat:@"%Y-%m-%d %H:%M:%S %z"];
       

		[CSVContent appendFormat:@"%@,%@,%@,%@,%@,%@\n", 
								currentUser, 
								[entry objectForKey:@"UserIP"], [date descriptionWithCalendarFormat:@"%Y/%m/%d"], [entry objectForKey:@"tc_type"],
								[entry objectForKey:@"tc_filename"],[entry objectForKey:@"tc_size"]];
	}
   
    NSString *CSVFile = [NSString stringWithFormat:@"%@\n%@", CSVHeader, CSVContent];
    
    [webpages setObject:CSVFile forKey:currentUser];

}


- (void)exportToCSV:(NSString*)path
{
    NSString *baseDir = path;
    NSArray *pages = [webpages allKeys];
    NSEnumerator *pagesEnum = [pages objectEnumerator];
    NSString *filename = nil;
    
    while ((filename = [pagesEnum nextObject]) != nil)
    {
        NSString *thePage = [webpages objectForKey:filename];
        [thePage writeToFile:[NSString stringWithFormat:@"%@/%@.csv", baseDir, filename] atomically:YES];
    }
    
}




@end
