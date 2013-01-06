/*
 PureFTPd Manager
 Copyright (C) 2003-2004 Jean-Matthieu Schaffhauser <jean-matthieu@users.sourceforge.net>
 
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


#import "UserStatsController.h"
#import "defines.h"

@implementation UserStatsController

-(id) init
{
    self = [super init];
    if (self)
    {
        
        if((userStatsDict = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPStatsFile]) == nil);
        userStatsDict = [[NSMutableDictionary alloc] init];
            
        statsParser=[[NSXLogParser alloc] initWithInfoCapacity:13];
    }
    
    return self;
}

-(void) dealloc
{
    [userStatsDict release];
    [statsParser release];
    [super dealloc];
}

-(NSMutableDictionary *) dictionary
{
      return userStatsDict;
}

-(void) parseFile:(NSString *)aPath withPattern:(NSString *) aPattern
{
    
    if ([aPattern isEqualToString:CLF_PATTERN])
        logFormat = [NSNumber numberWithInt:0];
    else if ([aPattern isEqualToString:W3C_PATTERN])
        logFormat = [NSNumber numberWithInt:1];
    //NSLog(@"Parsing with %@...", aPattern);
    
    NSString *fileContents = [[NSString alloc] initWithContentsOfFile:aPath];
    NSMutableArray *subjectsArray = [[NSMutableArray alloc] initWithArray:
            [fileContents componentsSeparatedByString:@"\n"]];
    
    if([subjectsArray count] <= 0){
        return;
    }
    
    [userStatsDict setDictionary:[NSDictionary dictionaryWithContentsOfFile:PureFTPStatsFile]];
    //NSLog (@"%@", [userStatsDict description]);
    
    NSNumber *wasLast = nil;
    lastLine = [[NSNumber alloc] initWithUnsignedInt:[subjectsArray count]];
    
    if (nil != (wasLast = [userStatsDict objectForKey:LASTLINE]))
    {
        if ([wasLast unsignedIntValue] == 0)
        {
            if ([logFormat intValue] == 1)
            {
               
                // Remove comments at beginning of W3C file
                [subjectsArray removeObjectsInRange:NSMakeRange(0,4)];
                //NSLog(@"%@", [subjectsArray description]);
            }
        }
        
        else if ([wasLast unsignedIntValue] < [lastLine unsignedIntValue])
        {
           
            [subjectsArray removeObjectsInRange:NSMakeRange(0,[wasLast unsignedIntValue]-1)];
        }
        
        else {
            
            return;   
        }
        
    }
    else 
    { 
        if ([logFormat intValue] == 1)
        {
            // Remove comments at beginning of W3C file
            [subjectsArray removeObjectsInRange:NSMakeRange(0,4)];
            //NSLog(@"%@", [subjectsArray description]);
        }
    }
    
    [userStatsDict setObject:lastLine forKey:LASTLINE];
     
    NSString *subjectToParse;
    NSEnumerator *myEnum = [subjectsArray objectEnumerator];
    
    while (subjectToParse = [myEnum nextObject])
    {
        //NSLog (@"%@", [subjectToParse description]);
        [statsParser parseLine:subjectToParse withPattern:aPattern];
    }
    [self orderUserStatsDict];
    [fileContents release];
    [subjectsArray release];
}

-(void) orderCLFStats
{
    
    NSMutableArray *statsArray = [[NSMutableArray alloc] init];
    [statsArray setArray:[statsParser infoArray]];
    NSArray *subArray = nil;
    NSEnumerator *logEnum = [statsArray objectEnumerator];  
    
    NSString *ysize = nil;
    NSString *msize = nil;
    NSString *dsize = nil;
    
    NSMutableArray *oldUserArray=nil;
    int month = 0;
    while(subArray = [logEnum nextObject]) {
        ysize = nil;
        msize=  nil;
        dsize = nil;
        NSString *monthString = [NSString stringWithString:[subArray objectAtIndex:4]];
        
        if ([monthString isEqualToString:@"Jan"])
            month=1;
        else if ([monthString isEqualToString:@"Feb"])
            month=2;
        else if ([monthString isEqualToString:@"Mar"])
            month=3;
        else if ([monthString isEqualToString:@"Apr"])
            month=4;
        else if ([monthString isEqualToString:@"May"])
            month=5;
        else if ([monthString isEqualToString:@"Jun"])
            month=6;
        else if ([monthString isEqualToString:@"Jul"])
            month=7;
        else if ([monthString isEqualToString:@"Aug"])
            month=8;
        else if ([monthString isEqualToString:@"Sep"])
            month=9;
        else if ([monthString isEqualToString:@"Oct"])
            month=10;
        else if ([monthString isEqualToString:@"Nov"])
            month=11;
        else if ([monthString isEqualToString:@"Dec"])
            month=12;
        NSString *theDate = [NSString stringWithFormat:@"%@-%02d-%@ %@:%@:%@ %@",
            [subArray objectAtIndex:5],
            month,
            [subArray objectAtIndex:3],
            [subArray objectAtIndex:6],
            [subArray objectAtIndex:7],
            [subArray objectAtIndex:8],
            [subArray objectAtIndex:9]];
        
        NSCalendarDate *transferDate = [[[NSCalendarDate alloc] initWithString:theDate] autorelease];
        
        
        NSArray *transferDescription = [[NSArray alloc] initWithObjects:
            [subArray objectAtIndex:1],
            [subArray objectAtIndex:10],
            [subArray objectAtIndex:11],
            [subArray objectAtIndex:12],
            transferDate,
            nil];
        
        NSArray *transferKeys = [[NSArray alloc] initWithObjects:USERIP, TYPE, FILENAME, FILESIZE, DATE, nil];
        
        NSMutableDictionary *newTransfer = [[NSMutableDictionary alloc] initWithObjects:transferDescription
                                                                                forKeys:transferKeys];
        
        
        NSMutableDictionary *totalsDict = nil;
        NSMutableDictionary *yearDict = nil;
        NSMutableDictionary *monthDict = nil;
        // Dict Keys
        NSString *year = [NSString stringWithFormat:@"%d", [transferDate yearOfCommonEra]];
        NSString *month = [NSString stringWithFormat:@"%d", [transferDate monthOfYear]];
        NSString *day = [NSString stringWithFormat:@"%d", [transferDate dayOfMonth]];
        
        if ((oldUserArray=[userStatsDict objectForKey:[subArray objectAtIndex:2]]) == nil)
        {
            // User not found, add it to userStatsDict
            // His first totals ...
            totalsDict = [[NSMutableDictionary alloc] init];
            yearDict =  [[NSMutableDictionary alloc] init];
            monthDict = [[NSMutableDictionary alloc] init];
            // Total per Day
            [monthDict setObject:[subArray objectAtIndex:12] 
                          forKey:day];
            // Monthly Total
            [monthDict setObject:[subArray objectAtIndex:12] forKey:@"monthTotal"];
            
            [yearDict setObject:monthDict forKey:month];
            // Year Total
            [yearDict setObject:[subArray objectAtIndex:12] 
                         forKey:@"yearTotal"];
            
            [totalsDict setObject:yearDict forKey:year];
            
            NSArray *userArray = [[NSArray alloc] initWithObjects: totalsDict, newTransfer, nil];
            
            [userStatsDict setObject:userArray forKey:[subArray objectAtIndex:2]];
            [yearDict release];
            [monthDict release];
            [totalsDict release];
            [userArray release];
        }
        else
        {
            NSMutableArray *userArray = [[NSMutableArray alloc] init];
            
            double totalToAdd = [[subArray objectAtIndex:12] doubleValue];
            totalsDict = [[NSMutableDictionary alloc] init];
          
            yearDict = [NSMutableDictionary dictionaryWithDictionary:[[oldUserArray objectAtIndex:0] objectForKey:year]];
            monthDict = [NSMutableDictionary dictionaryWithDictionary:[yearDict objectForKey:month]];
           
            ysize = [yearDict objectForKey:@"yearTotal"];
            if (ysize == NULL)
            {
                // Happy New Year ! (New Month new day)
                [yearDict setObject:[subArray objectAtIndex:12] 
                             forKey:@"yearTotal"];
                [monthDict setObject:[subArray objectAtIndex:12]
                              forKey:@"monthTotal"];
                [monthDict setObject:[subArray objectAtIndex:12]
                              forKey:day];
            }
            else 
            {
                // Update year total
                [yearDict setObject:[NSString stringWithFormat:@"%f", [ysize doubleValue] + totalToAdd]
                             forKey:@"yearTotal"];
                
                
                msize = [monthDict objectForKey:@"monthTotal"];
                if (msize==NULL)
                {
                    // New month! ... and new day
                    [monthDict setObject:[subArray objectAtIndex:12] 
                                  forKey:@"monthTotal"];
                    [monthDict setObject:[subArray objectAtIndex:12] 
                                  forKey:day];
                }
                else 
                {
                    dsize = [monthDict objectForKey:day];
                    
                    if (dsize == NULL)
                    {
                        // New Day 
                        [monthDict setObject:[subArray objectAtIndex:12] forKey:day];
                    }
                    else
                    {
                        [monthDict setObject:[NSString stringWithFormat:@"%f", [dsize doubleValue] + totalToAdd]
                                      forKey:day];
                    }
                    
                    [monthDict setObject:[NSString stringWithFormat:@"%f", [msize doubleValue] + totalToAdd]
                                  forKey:@"monthTotal"];
                }        
                
            }
            
            [yearDict setObject:monthDict forKey:month];
            
            [totalsDict setObject:yearDict forKey:year];
            
            [userArray addObject:totalsDict];
            
            [userArray addObjectsFromArray:oldUserArray];
            [userArray removeObjectAtIndex:1];
            [userArray addObject:newTransfer];
            [userStatsDict setObject:userArray forKey:[subArray objectAtIndex:2]];
            [totalsDict release];   
            [userArray release];
        }
        
        [transferDescription release];
    }
    
    
    [userStatsDict writeToFile:PureFTPStatsFile atomically:YES];
    [statsParser clearLoginfoArray];
    
    [lastLine release];
    [statsArray release];
}

-(void) orderW3CStats
{
    
    NSMutableArray *statsArray = [[NSMutableArray alloc] init];
    [statsArray setArray:[statsParser infoArray]];
    NSArray *subArray = nil;
    NSEnumerator *logEnum = [statsArray objectEnumerator];
    NSMutableArray *oldUserArray=nil;
    
    NSString *ysize = nil;
    NSString *msize = nil;
    NSString *dsize = nil;
    
    [userStatsDict setObject:lastLine forKey:LASTLINE];
    
    
    while(subArray = [logEnum nextObject]) {
        ysize = nil;
        msize=  nil;
        dsize = nil;
        
        NSString *theDate = [NSString stringWithFormat:@"%@ %@ +0000",
            [subArray objectAtIndex:1],
            [subArray objectAtIndex:2]];
       // NSLog(@"%@", theDate);
        NSCalendarDate *transferDate = [[[NSCalendarDate alloc] initWithString:theDate] autorelease];
        
        NSString *sizeinBytes = [NSString stringWithFormat:@"%f", [[subArray objectAtIndex:7] doubleValue]];
        
        NSArray *transferDescription = [[NSArray alloc] initWithObjects:
            [subArray objectAtIndex:3],
            [subArray objectAtIndex:4],
            [subArray objectAtIndex:5],
            sizeinBytes,
            transferDate,
            nil];
        
        NSArray *transferKeys = [[NSArray alloc] initWithObjects:USERIP, TYPE, FILENAME, FILESIZE, DATE, nil];
        
        NSMutableDictionary *newTransfer = [[NSMutableDictionary alloc] initWithObjects:transferDescription
                                                                                forKeys:transferKeys];
        
        
        NSMutableDictionary *totalsDict = nil;
        NSMutableDictionary *yearDict = nil;
        NSMutableDictionary *monthDict = nil;
        // Dict Keys
        NSString *year = [NSString stringWithFormat:@"%d", [transferDate yearOfCommonEra]];
        NSString *month = [NSString stringWithFormat:@"%d", [transferDate monthOfYear]];
        NSString *day = [NSString stringWithFormat:@"%d", [transferDate dayOfMonth]];
        
        if ((oldUserArray=[userStatsDict objectForKey:[subArray objectAtIndex:6]]) == nil)
        {
            // User not found, add it to userStatsDict
            // His first totals ...
            totalsDict = [[NSMutableDictionary alloc] init];
            yearDict =  [[NSMutableDictionary alloc] init];
            monthDict = [[NSMutableDictionary alloc] init];
            // Total per Day
            [monthDict setObject:sizeinBytes
                          forKey:day];
            // Monthly Total
            [monthDict setObject:sizeinBytes forKey:@"monthTotal"];
            
            [yearDict setObject:monthDict forKey:month];
            // Year Total
            [yearDict setObject:sizeinBytes 
                         forKey:@"yearTotal"];
            
            [totalsDict setObject:yearDict forKey:year];
            
            NSArray *userArray = [[NSArray alloc] initWithObjects: totalsDict, newTransfer, nil];
            
            [userStatsDict setObject:userArray forKey:[subArray objectAtIndex:6]];
            [yearDict release];
            [monthDict release];
            [totalsDict release];
            [userArray release];
        }
        else
        {
            NSMutableArray *userArray = [[NSMutableArray alloc] init];
            
            double totalToAdd = [sizeinBytes doubleValue];
            totalsDict = [[NSMutableDictionary alloc] init];
            yearDict = [NSMutableDictionary dictionaryWithDictionary:[[oldUserArray objectAtIndex:0] objectForKey:year]];
            monthDict = [NSMutableDictionary dictionaryWithDictionary:[yearDict objectForKey:month]];
            
            ysize = [yearDict objectForKey:@"yearTotal"];
            if (ysize ==  NULL)
            {
                // Happy New Year ! (New Month new day)
                [yearDict setObject:sizeinBytes 
                             forKey:@"yearTotal"];
                [monthDict setObject:sizeinBytes
                              forKey:@"monthTotal"];
                [monthDict setObject:sizeinBytes
                              forKey:day];
            }
            else 
            {
                // Update year total
                [yearDict setObject:[NSString stringWithFormat:@"%f", [ysize doubleValue] + totalToAdd]
                             forKey:@"yearTotal"];
                
                
                msize = [monthDict objectForKey:@"monthTotal"];
                if (msize == NULL)
                {
                    // New month! ... and new day
                    [monthDict setObject:sizeinBytes 
                                  forKey:@"monthTotal"];
                    [monthDict setObject:sizeinBytes
                                  forKey:day];
                }
                else 
                {
                    dsize = [monthDict objectForKey:day];
                    
                    if (dsize == NULL)
                    {
                        // New Day 
                        [monthDict setObject:sizeinBytes
                                      forKey:day];
                    }
                    else
                    {
                        [monthDict setObject:[NSString stringWithFormat:@"%f", [dsize doubleValue] + totalToAdd]
                                      forKey:day];
                    }
                    
                    [monthDict setObject:[NSString stringWithFormat:@"%f", [msize doubleValue] + totalToAdd]
                                  forKey:@"monthTotal"];
                }        
                
            }
            
            [yearDict setObject:monthDict forKey:month];
            
            [totalsDict setObject:yearDict forKey:year];
            [userArray addObject:totalsDict];
            
            [userArray addObjectsFromArray:oldUserArray];
            [userArray removeObjectAtIndex:1];
            [userArray addObject:newTransfer];
            [userStatsDict setObject:userArray forKey:[subArray objectAtIndex:6]];
            [totalsDict release];   
            [userArray release];
        }
        [transferDescription release];
    }

    [userStatsDict writeToFile:PureFTPStatsFile atomically:YES];
    [statsParser clearLoginfoArray];
    
    [lastLine release];
    [statsArray release];
}

-(void) orderUserStatsDict
{
    if ([logFormat intValue] == 0){
        [self orderCLFStats];
    }
    else if ([logFormat intValue] == 1) {
        [self orderW3CStats];
    }
}

@end
