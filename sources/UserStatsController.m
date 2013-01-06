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
        
        /*if((userStatsDict = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPStatsFile]) == nil)
			userStatsDict = [[NSMutableDictionary alloc] init];*/
            
        statsParser=[[NSXLogParser alloc] initWithInfoCapacity:13];
    }
    
    return self;
}

-(void) dealloc
{
    if (userStatsDict != nil)
	{
		[userStatsDict release];
	}
	
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
    
	[fileContents release];
	
    if([subjectsArray count] <= 0)
	{	
		
		[subjectsArray release];
        return;
    }
	
	if (userStatsDict != nil)
	{
		[userStatsDict removeAllObjects];
		[userStatsDict release];
	}
	
    if ((userStatsDict = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPStatsFile]) == nil)
		userStatsDict = [[NSMutableDictionary alloc] init];
    
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
			[subjectsArray release];
			[lastLine release];
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
    while((subArray = [logEnum nextObject]) != nil) {
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
        /*
			NSString *theDate = [NSString stringWithFormat:@"%@-%02d-%@ %@:%@:%@ %@",
            [subArray objectAtIndex:5],
            month,
            [subArray objectAtIndex:3],
            [subArray objectAtIndex:6],
            [subArray objectAtIndex:7],
            [subArray objectAtIndex:8],
            [subArray objectAtIndex:9]];
        */
		//NSCalendarDate *transferDate = [[[NSCalendarDate alloc] initWithString:theDate] autorelease];
		 
		int y = [[subArray objectAtIndex:5] intValue];
		int m = month;
		int d = [[subArray objectAtIndex:3] intValue];
		int hour = [[subArray objectAtIndex:6] intValue];
		int minute = [[subArray objectAtIndex:7] intValue];
		int second = [[subArray objectAtIndex:8] intValue];
		NSTimeZone *tz = [NSTimeZone localTimeZone];
		 
       
        NSCalendarDate *transferDate = [[[NSCalendarDate alloc] initWithYear:y month:m day:d 
																		hour:hour minute:minute second:second 
																	timeZone:tz] autorelease];
		
        NSString *filename = nil;
		NSURL *url = [NSURL URLWithString:[subArray objectAtIndex:11]];
		if (url == nil)
		{
			if ([filename respondsToSelector:@selector(stringWithCString:encoding:)])
			{
				filename = [NSString stringWithCString:[[subArray objectAtIndex:11] cString] encoding:NSUTF8StringEncoding];
			} else {
				filename = [NSString stringWithUTF8String:[[subArray objectAtIndex:11] cString]];
			}
		} else {
			if ([url path] !=nil){
				filename = [NSString stringWithString:[url path]];
			} else { 
				//filename=[NSString stringWithCString:[[subArray objectAtIndex:11] cString] encoding:NSUTF8StringEncoding];
				if ([filename respondsToSelector:@selector(stringWithCString:encoding:)])
				{
					filename = [NSString stringWithCString:[[subArray objectAtIndex:11] cString] encoding:NSUTF8StringEncoding];
				} else {
					filename = [NSString stringWithUTF8String:[[subArray objectAtIndex:11] cString]];
				}
			}
			
		}
        NSArray *transferDescription = [[NSArray alloc] initWithObjects:
            [subArray objectAtIndex:1],
			[subArray objectAtIndex:10],
            filename,
            [subArray objectAtIndex:12],
            transferDate,
            nil];
        
        NSArray *transferKeys = [[NSArray alloc] initWithObjects:USERIP, TYPE, FILENAME, FILESIZE, DATE, nil];
        
        NSMutableDictionary *newTransfer = [[NSMutableDictionary alloc] initWithObjects:transferDescription
                                                                                forKeys:transferKeys];
		
        [transferDescription release];
		[transferKeys release];
		
        NSMutableDictionary *totalsDict = nil;
        NSMutableDictionary *yearDict = nil;
        NSMutableDictionary *monthDict = nil;
        // Dict Keys
        NSString *year = [NSString stringWithFormat:@"%d", [transferDate yearOfCommonEra]];
        NSString *month = [NSString stringWithFormat:@"%d", [transferDate monthOfYear]];
        NSString *day = [NSString stringWithFormat:@"%d", [transferDate dayOfMonth]];
        
		oldUserArray=[userStatsDict objectForKey:[subArray objectAtIndex:2]];
        if (oldUserArray == nil)
        {
            // User not found, add it to userStatsDict
            // His first totals ...
            totalsDict = [[NSMutableDictionary alloc] init];
            yearDict =  [[NSMutableDictionary alloc] init];
            monthDict = [[NSMutableDictionary alloc] init];
            // Total per Day
            // Total per Day
			// [subArray objectAtIndex:4] PUT | GET
			NSMutableDictionary *transfers = [[NSMutableDictionary alloc] init];
			[transfers setObject:[subArray objectAtIndex:12] forKey:[subArray objectAtIndex:10]];
			
            [monthDict setObject:transfers
                          forKey:day];
            // Monthly Total
            [monthDict setObject:transfers forKey:@"monthTotal"];
            
            [yearDict setObject:monthDict forKey:month];
            // Year Total
            [yearDict setObject:transfers 
                         forKey:@"yearTotal"];
            
            [totalsDict setObject:yearDict forKey:year];
			
            NSArray *userArray = [NSArray arrayWithObjects: totalsDict, newTransfer, nil];
            
            [userStatsDict setObject:userArray forKey:[subArray objectAtIndex:2]];
            [yearDict release];
            [monthDict release];
            [totalsDict release];
            [transfers release];
        }
        else
        {
            NSMutableArray *userArray = [[NSMutableArray alloc] init];
            NSString *transferType = [subArray objectAtIndex:10]; // PUT | GET
            double totalToAdd = [[subArray objectAtIndex:12] doubleValue];
            totalsDict = [[NSMutableDictionary alloc] init];
			
			NSDictionary *d = [[oldUserArray objectAtIndex:0] objectForKey:year];
			
			if (d!=nil){
				yearDict = [NSMutableDictionary dictionaryWithDictionary:d];
			} else {
				yearDict= [NSMutableDictionary dictionary];
			}
				
			d = [yearDict objectForKey:month];
			if (d!=nil)
			{
				monthDict = [NSMutableDictionary dictionaryWithDictionary:d];
			} else {
				monthDict= [NSMutableDictionary dictionary];
				[yearDict setObject:monthDict forKey:month];
			}
			
			d = [yearDict objectForKey:@"yearTotal"];
			NSMutableDictionary *yearDetail = nil;
			if (d!=nil)
			{
				yearDetail = [NSMutableDictionary dictionaryWithDictionary:d];
			} else {
				yearDetail= [NSMutableDictionary dictionary];
				[yearDict setObject:yearDetail forKey:@"yearTotal"];
			}
			
			d = [monthDict objectForKey:@"monthTotal"];
			NSMutableDictionary *monthDetail = nil;
			if (d!=nil)
			{
				monthDetail = [NSMutableDictionary dictionaryWithDictionary:d];
			} else {
				monthDetail= [NSMutableDictionary dictionary];
				[monthDict setObject:monthDetail forKey:@"monthTotal"];
			}
			
			d = [monthDict objectForKey:day];
			NSMutableDictionary *dayDetail = nil;
			if (d!=nil)
			{
				dayDetail = [NSMutableDictionary dictionaryWithDictionary:d];
			} else {
				dayDetail= [NSMutableDictionary dictionary];
				[monthDict setObject:dayDetail forKey:day];
			}

            ysize = [yearDetail objectForKey:transferType];
           
            if (ysize == nil) // no record for this type of transfer.
            {
				[yearDetail setObject:[subArray objectAtIndex:12] forKey:transferType];
				[monthDetail setObject:[subArray objectAtIndex:12] forKey:transferType];
				[dayDetail setObject:[subArray objectAtIndex:12] forKey:transferType];
				
				[monthDict setObject:dayDetail forKey:day];
				// Monthly Total
				[monthDict setObject:monthDetail forKey:@"monthTotal"];
            
				[yearDict setObject:monthDict forKey:month];
				// Year Total
				[yearDict setObject:yearDetail forKey:@"yearTotal"];
            }
            else 
            {
                // Update year total
				// get year transfer dictionary
				//NSMutableDictionary *yearTransfers = [NSMutableDictionary dictionaryWithDictionary:[yearDict objectForKey:@"yearTotal"]];
				
				[yearDetail setObject:[NSString stringWithFormat:@"%f", [ysize doubleValue] + totalToAdd] 
							  forKey:transferType];
                [yearDict setObject:yearDetail
                             forKey:@"yearTotal"];
                
                
                msize = [monthDetail objectForKey:transferType];
                if (msize==NULL)
                {
					[monthDetail setObject:[subArray objectAtIndex:12] forKey:transferType];
					[dayDetail setObject:[subArray objectAtIndex:12] forKey:transferType];
					
                    [monthDict setObject:monthDetail forKey:@"monthTotal"];
                    [monthDict setObject:dayDetail forKey:day];
				}
                else 
                {
                    dsize = [[monthDict objectForKey:day] objectForKey:transferType];
                    
                    if (dsize == NULL)
                    {
                        // New Day 
                        [dayDetail setObject:[subArray objectAtIndex:12] forKey:transferType];
                        [monthDict setObject:dayDetail forKey:day];
                    }
                    else
                    {
						[dayDetail setObject:[NSString stringWithFormat:@"%f", [dsize doubleValue] + totalToAdd] 
							             forKey:transferType];
							  
                        [monthDict setObject:dayDetail forKey:day];
                    }
                    
					[monthDetail setObject:[NSString stringWithFormat:@"%f", [msize doubleValue] + totalToAdd] 
							  forKey:transferType];
                    [monthDict setObject:monthDetail forKey:@"monthTotal"];
                }        
                
            }
            
            [yearDict setObject:monthDict forKey:month];
            
            [totalsDict setObject:yearDict forKey:year];
			
            //NSLog(year);
            //NSLog([oldUserArray description]);            
            //NSLog([totalsDict description]);

            
            //[userArray addObject:totalsDict];
            [userArray addObjectsFromArray:oldUserArray];
            [[userArray objectAtIndex:0] setObject:yearDict forKey:year];
            //[userArray removeObjectAtIndex:1];
            [userArray addObject:newTransfer];
            [userStatsDict setObject:userArray forKey:[subArray objectAtIndex:2]];
            [totalsDict release];   
            [userArray release];
        }
        
        [newTransfer release];
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
        
        /* NSString *theDate = [NSString stringWithFormat:@"%@ %@ +0000",
            [subArray objectAtIndex:1],
            [subArray objectAtIndex:2]];
		*/
       // NSLog(@"%@", theDate);
		int y = [[[subArray objectAtIndex:1] substringWithRange:NSMakeRange(0,4)] intValue];
		int m = [[[subArray objectAtIndex:1] substringWithRange:NSMakeRange(5,2)] intValue];
		int d = [[[subArray objectAtIndex:1] substringWithRange:NSMakeRange(8,2)] intValue];
		int hour = [[[subArray objectAtIndex:2] substringWithRange:NSMakeRange(0,2)] intValue];
		int minute = [[[subArray objectAtIndex:2] substringWithRange:NSMakeRange(3,2)] intValue];
		int second = [[[subArray objectAtIndex:2] substringWithRange:NSMakeRange(6,2)] intValue];
		NSTimeZone *tz = [NSTimeZone timeZoneWithName:@"GMT"];
		 
        //NSCalendarDate *transferDate = [[[NSCalendarDate alloc] initWithString:theDate] autorelease];
        NSCalendarDate *transferDate = [[[NSCalendarDate alloc] initWithYear:y month:m day:d 
																		hour:hour minute:minute second:second 
																	timeZone:tz] autorelease];
        
        NSString *sizeinBytes = [NSString stringWithFormat:@"%f", [[subArray objectAtIndex:7] doubleValue]];
        
		
	    NSString *filename = nil;
		NSURL *url = [NSURL URLWithString:[subArray objectAtIndex:5]];
		if (url == nil)
		{
			if ([filename respondsToSelector:@selector(stringWithCString:encoding:)])
			{
				filename = [NSString stringWithCString:[[subArray objectAtIndex:5] cString] encoding:NSUTF8StringEncoding];
			} else {
				filename = [NSString stringWithUTF8String:[[subArray objectAtIndex:5] cString]];
			}
			
		} else {
			if ([url path] !=nil) {
				filename = [NSString stringWithString:[url path]];
			} else {
				if ([filename respondsToSelector:@selector(stringWithCString:encoding:)])
				{
					filename = [NSString stringWithCString:[[subArray objectAtIndex:5] cString] encoding:NSUTF8StringEncoding];
				} else {
					filename = [NSString stringWithUTF8String:[[subArray objectAtIndex:5] cString]];
				}
				//filename=[NSString stringWithCString:[[subArray objectAtIndex:5] cString] encoding:NSUTF8StringEncoding];
			}
		}
		
		NSString *transferType = [subArray objectAtIndex:4]; // PUT | GET
		if ([transferType isEqualToString:@"created"])
			transferType=@"PUT";
		else if  ([transferType isEqualToString:@"sent"])
			transferType=@"GET";
				
        NSArray *transferDescription = [[NSArray alloc] initWithObjects:
            [subArray objectAtIndex:3],
            transferType,
            filename,
            sizeinBytes,
            transferDate,
            nil];
        
        NSArray *transferKeys = [[NSArray alloc] initWithObjects:USERIP, TYPE, FILENAME, FILESIZE, DATE, nil];
        
        NSMutableDictionary *newTransfer = [[NSMutableDictionary alloc] initWithObjects:transferDescription
                                                                                forKeys:transferKeys];
        
		[transferDescription release];
		[transferKeys release];
        
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
            // User not found, add it to userStatsDict
            // His first totals ...
            totalsDict = [[NSMutableDictionary alloc] init];
            yearDict =  [[NSMutableDictionary alloc] init];
            monthDict = [[NSMutableDictionary alloc] init];
            // Total per Day
            // Total per Day
			// [subArray objectAtIndex:4] PUT | GET
			
			NSMutableDictionary *transfers = [[NSMutableDictionary alloc] init];
			[transfers setObject:sizeinBytes forKey:transferType];
			
            [monthDict setObject:transfers
                          forKey:day];
            // Monthly Total
            [monthDict setObject:transfers forKey:@"monthTotal"];
            
            [yearDict setObject:monthDict forKey:month];
            // Year Total
            [yearDict setObject:transfers 
                         forKey:@"yearTotal"];
            
            [totalsDict setObject:yearDict forKey:year];
			
            NSArray *userArray = [NSArray arrayWithObjects: totalsDict, newTransfer, nil];
            
            [userStatsDict setObject:userArray forKey:[subArray objectAtIndex:6]];
            [yearDict release];
            [monthDict release];
            [totalsDict release];
            [transfers release];
        }
        else
        {
            NSMutableArray *userArray = [[NSMutableArray alloc] init];
            
            double totalToAdd = [sizeinBytes doubleValue];
            totalsDict = [[NSMutableDictionary alloc] init];
			
			NSDictionary *d = [[oldUserArray objectAtIndex:0] objectForKey:year];
			if (d!=nil)
			{
				yearDict = [NSMutableDictionary dictionaryWithDictionary:d];
			} else {
				yearDict= [NSMutableDictionary dictionary];
			}
            				
			d = [yearDict objectForKey:month];
			if (d!=nil)
			{
				monthDict = [NSMutableDictionary dictionaryWithDictionary:d];
			}else {
				monthDict= [NSMutableDictionary dictionary];
				[yearDict setObject:monthDict forKey:month];
			}
					
            
			
			d = [yearDict objectForKey:@"yearTotal"];
			NSMutableDictionary *yearDetail = nil;
			if (d!=nil)
			{
				yearDetail = [NSMutableDictionary dictionaryWithDictionary:d];
			} else {
				yearDetail= [NSMutableDictionary dictionary];
				[yearDict setObject:yearDetail forKey:@"yearTotal"];
			}
			
			d = [monthDict objectForKey:@"monthTotal"];
			NSMutableDictionary *monthDetail = nil;
			if (d!=nil)
			{
				monthDetail = [NSMutableDictionary dictionaryWithDictionary:d];
			} else {
				monthDetail= [NSMutableDictionary dictionary];
				[monthDict setObject:monthDetail forKey:@"monthTotal"];
			}
			
			d = [monthDict objectForKey:day];
			NSMutableDictionary *dayDetail = nil;
			if (d!=nil)
			{
				dayDetail = [NSMutableDictionary dictionaryWithDictionary:d];
			} else {
				dayDetail= [NSMutableDictionary dictionary];
				[monthDict setObject:dayDetail forKey:day];
			}

            ysize = [yearDetail objectForKey:transferType];
           
            if (ysize == nil) // no record for this type of transfer.
            {
				[yearDetail setObject:sizeinBytes forKey:transferType];
				[monthDetail setObject:sizeinBytes forKey:transferType];
				[dayDetail setObject:sizeinBytes forKey:transferType];
				
				[monthDict setObject:dayDetail forKey:day];
				// Monthly Total
				[monthDict setObject:monthDetail forKey:@"monthTotal"];
            
				[yearDict setObject:monthDict forKey:month];
				// Year Total
				[yearDict setObject:yearDetail forKey:@"yearTotal"];
            }
            else 
            {
                // Update year total
				// get year transfer dictionary
				//NSMutableDictionary *yearTransfers = [NSMutableDictionary dictionaryWithDictionary:[yearDict objectForKey:@"yearTotal"]];
				
				[yearDetail setObject:[NSString stringWithFormat:@"%f", [ysize doubleValue] + totalToAdd] 
							  forKey:transferType];
                [yearDict setObject:yearDetail
                             forKey:@"yearTotal"];
                
                
                msize = [monthDetail objectForKey:transferType];
                if (msize==NULL)
                {
					[monthDetail setObject:sizeinBytes forKey:transferType];
					[dayDetail setObject:sizeinBytes forKey:transferType];
					
                    [monthDict setObject:monthDetail forKey:@"monthTotal"];
                    [monthDict setObject:dayDetail forKey:day];
				}
                else 
                {
                    dsize = [[monthDict objectForKey:day] objectForKey:transferType];
                    
                    if (dsize == NULL)
                    {
                        // New Day 
                        [dayDetail setObject:sizeinBytes forKey:transferType];
                        [monthDict setObject:dayDetail forKey:day];
                    }
                    else
                    {
						[dayDetail setObject:[NSString stringWithFormat:@"%f", [dsize doubleValue] + totalToAdd] 
							             forKey:transferType];
							  
                        [monthDict setObject:dayDetail forKey:day];
                    }
                    
					[monthDetail setObject:[NSString stringWithFormat:@"%f", [msize doubleValue] + totalToAdd] 
							  forKey:transferType];
                    [monthDict setObject:monthDetail forKey:@"monthTotal"];
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
		
        [newTransfer release];
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
