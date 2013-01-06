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

#import "GraphController.h"

@implementation GraphController

// The pointer to the singleton instance
static GraphController *theGraphController = nil;

/* Get the singleton instance of this class */
+(id) getInstance
{
    // TODO: Mutex Begin
    if (theGraphController == nil) {
        theGraphController = [[GraphController alloc] init];
    }
    // TODO: Mutex End
    return theGraphController;
}

-(id) init
{
    self = [super init];
    if(self)
    {
        theGraphController = self;
        sizeUnit = 1;
        koctet = 1024;
        moctet = koctet*1024;
        goctet = moctet * 1024;
    }
    
    return self;
}

-(void) dealloc 
{
    [userTraffic release];
    [super dealloc];
}

-(void) awakeFromNib
{
    
    
    // Inset the X Axis a bit to give enough room for the bars to display.
    [ graphView setAxisInset:[ SM2DGraphView barWidth ] forAxis:kSM2DGraph_Axis_X ];
    userTraffic = [[NSDictionary alloc] init];
   // [ self refreshUserGraphView ];
    //[self gatherIndexes];
}

-(void) refreshUserGraphView
{
    if ([self gatherIndexes])
        [graphView refreshDisplay:self];
}


-(BOOL) gatherIndexes
{
    NSMutableDictionary *usersDictionary;
    usersDictionary = [NSMutableDictionary dictionaryWithContentsOfFile:PureFTPStatsFile];
    NSArray *keyArray = [NSArray arrayWithArray:[[LogManager getInstance] sortedArray]];
    
    
    NSArray *userArray = [usersDictionary objectForKey:[[keyArray objectAtIndex:[[[LogManager getInstance] usersTable] selectedRow]] objectForKey:@"account"]];
    
    if (userTraffic)
        [userTraffic release];
    
    userTraffic = [[NSDictionary alloc] initWithDictionary:[userArray  objectAtIndex:0]];
    //NSLog(@"%@", [userTraffic description]);
     
     switch ([[totalUnits selectedItem] tag]){
         case 0:     // Terabytes
             [graphView setNumberOfTickMarks:3 forAxis:kSM2DGraph_Axis_Y];
             [graphView setDrawsGrid:YES];
             break;
         case 1:     // GBytes
             [graphView setNumberOfTickMarks:20 forAxis:kSM2DGraph_Axis_Y];
             [graphView setDrawsGrid:YES];
             break;
         case 2:     //MBytes
             [graphView setNumberOfTickMarks:1000 forAxis:kSM2DGraph_Axis_Y];
             [graphView setDrawsGrid:NO];
             break;
     }
    
     return TRUE;
     
}




- (unsigned int)numberOfLinesInTwoDGraphView:(SM2DGraphView *)inGraphView
{
    return 2;
}

- (NSArray *)twoDGraphView:(SM2DGraphView *)inGraphView dataForLineIndex:(unsigned int)inLineIndex
{
    NSMutableArray	*result = nil;
    
    int monthTag = [[graphMonthPop selectedItem] tag];
    NSDictionary *yearTraffic = [NSDictionary dictionaryWithDictionary:[userTraffic objectForKey:[NSString stringWithFormat:@"%d", [[graphYearPop selectedItem] tag]]]];
    float xInset=0;
					
    if (monthTag != 0)
    {
        [inGraphView setNumberOfTickMarks:31 forAxis:kSM2DGraph_Axis_X];
        NSDictionary *monthTraffic = [NSDictionary dictionaryWithDictionary:[yearTraffic objectForKey:[NSString stringWithFormat:@"%d", monthTag]]];
        NSArray *monthKeys = [NSArray arrayWithArray:[monthTraffic allKeys]];
    
        NSEnumerator *trafficEnum = [monthKeys objectEnumerator];
        NSString *aKey;
        double traffic = 0;
		NSString *transferType = @"PUT";
        if ( inLineIndex == 0 )
        {
			transferType=@"GET";
		}
            result = [NSMutableArray array];
            while ((aKey = [trafficEnum nextObject]))
            {   
                if (![aKey isEqualToString:@"monthTotal"])
                {
                    switch ([[totalUnits selectedItem] tag])
                    {
                        case 0:
                            traffic = [[[monthTraffic objectForKey:aKey] objectForKey:transferType] doubleValue] / goctet;
                            traffic/= 1024;
                            if (traffic > 3)
                                traffic = 3;
                            break;
                        case 1:
                             traffic = [[[monthTraffic objectForKey:aKey] objectForKey:transferType] doubleValue] / goctet;
                            if (traffic > 20)
                                traffic = 20;
                            break;
                        case 2:
                             traffic = [[[monthTraffic objectForKey:aKey] objectForKey:transferType] doubleValue] / moctet;
                            if (traffic > 1000)
                                traffic = 1000;
                            break;
                    }   
                    
                    if (inLineIndex==1)
					{
						xInset=0.1;
					}   else if (inLineIndex==0)
					{
						xInset=-0.1;
					}
                    NSString *infoString = [NSString stringWithFormat:@"{%d,%f}", [aKey intValue], traffic];
                    //NSLog(@"%@", [infoString description]);
                    [result addObject:infoString];
                }
            }
        //}
    }
    
    // Show Annual traffic
    else 
    {
        [inGraphView setNumberOfTickMarks:12 forAxis:kSM2DGraph_Axis_X];
        NSArray *monthKeys=[yearTraffic allKeys];
        
        NSEnumerator *trafficEnum = [monthKeys objectEnumerator];
        NSString *aKey;
        double traffic=0;
        
		NSString *transferType = @"PUT";
        if ( inLineIndex == 0 )
        {
			transferType=@"GET";
		}
		
           result = [NSMutableArray array];
            while (aKey = [trafficEnum nextObject])
            {   
                if ( ![aKey isEqualToString:@"yearTotal"] ) {
                    
                    switch ([[totalUnits selectedItem] tag])
                    {
                        case 0:
                            traffic = [[[[yearTraffic objectForKey:aKey] objectForKey:@"monthTotal"] objectForKey:transferType] doubleValue] / goctet;
                            traffic/= 1024;
                            if (traffic > 3)
                                traffic = 3;
                            break;
                        case 1:
                            traffic = [[[[yearTraffic objectForKey:aKey] objectForKey:@"monthTotal"] objectForKey:transferType] doubleValue] / goctet;
                            if (traffic > 20)
                                traffic = 20;
                            break;
                        case 2:
                            traffic = [[[[yearTraffic objectForKey:aKey] objectForKey:@"monthTotal"] objectForKey:transferType] doubleValue] / moctet;
                            if (traffic > 1000)
                                traffic = 1000;
                            break;
                    }
					if (inLineIndex==1)
					{
						xInset=0.05;
					}   else if (inLineIndex==0)
					{
						xInset=-0.05;
					}
                    NSString *infoString = [NSString stringWithFormat:@"{%d,%f}", [aKey intValue], traffic];
                    [result addObject:infoString];
                }
            }
            //NSLog(@"result array : %@", [result description]);
        
    }
    
       
    return result;
}


- (double)twoDGraphView:(SM2DGraphView *)inGraphView maximumValueForLineIndex:(unsigned int)inLineIndex
                forAxis:(SM2DGraphAxisEnum)inAxis
{
    double	result = 0.0;
    
    if ( inGraphView == graphView )
    {
        
        if (inAxis == kSM2DGraph_Axis_Y) {
            switch ([[totalUnits selectedItem] tag]){
                case 0:     // Terabytes
                    return  2.0;
                    break;
                case 1:     // GBytes
                    return 20.0;
                    break;
                case 2:     //MBytes
                    return  1000.0;
                    break;
            }
        }
        
        else if ( (inAxis == kSM2DGraph_Axis_X) && ([[graphMonthPop selectedItem] tag] != 0))
            return  31.0;
        else 
            return  12.0;
        
    }
    
    return result;
}

- (double)twoDGraphView:(SM2DGraphView *)inGraphView minimumValueForLineIndex:(unsigned int)inLineIndex
                forAxis:(SM2DGraphAxisEnum)inAxis
{
    double	result = 0.0;
    if ( inAxis == kSM2DGraph_Axis_X )
        return 1.0;
    
    return result;
}

- (NSDictionary *)twoDGraphView:(SM2DGraphView *)inGraphView attributesForLineIndex:(unsigned int)inLineIndex
{
    NSDictionary	*result = nil;
    
    if ( inGraphView == graphView && inLineIndex == 0 ) // GET
    {
        // Make this a blackbar graph.
        result = [ NSDictionary dictionaryWithObjectsAndKeys:
            [ NSNumber numberWithBool:YES ], SM2DGraphBarStyleAttributeName,
            [ NSColor redColor ], NSForegroundColorAttributeName,
            nil ];
    } else if ( inGraphView == graphView && inLineIndex == 1 ) // PUT
	{
		result = [ NSDictionary dictionaryWithObjectsAndKeys:
			[ NSNumber numberWithBool:YES ], SM2DGraphBarStyleAttributeName,
            [ NSColor blueColor], NSForegroundColorAttributeName,
            nil ];
	}
        
    return result;
}


#pragma mark -
#pragma mark ¥ SM2DGRAPHVIEW DELEGATE METHODS

- (NSString *)twoDGraphView:(SM2DGraphView *)inGraphView labelForTickMarkIndex:(unsigned int)inTickMarkIndex
                    forAxis:(SM2DGraphAxisEnum)inAxis defaultLabel:(NSString *)inDefault
{
    NSString	*result = inDefault;
    if ( inGraphView == graphView )
    {
        if( inAxis == kSM2DGraph_Axis_X )
        {
            return [NSString stringWithFormat:@"%d", inTickMarkIndex+1];
        }
        else if (inAxis == kSM2DGraph_Axis_Y) 
        { 
            if ([[totalUnits selectedItem] tag] == 0)
                return [NSString stringWithFormat:@"%d", inTickMarkIndex];
            
            else if([[totalUnits selectedItem] tag] == 1)
            {   
                if ((inTickMarkIndex%4) == 0)
                   return [NSString stringWithFormat:@"%d", inTickMarkIndex];
                else return @"";
            }
            
            else if([[totalUnits selectedItem] tag] == 2)
            {
                if ((inTickMarkIndex%100) == 0)
                    return [NSString stringWithFormat:@"%d", inTickMarkIndex];
                else return @"";
            }
        }
        
        else
            result=@"";
    
    }
    
        
    return result;
}



- (void)twoDGraphView:(SM2DGraphView *)inGraphView doneDrawingLineIndex:(unsigned int)inLineIndex
{
    // This is just an example of what you could do...
    //    if ( inGraphView == _sm_trigGraph )
    //        NSLog( @"We're done drawing the sine/cosine line number %d.", inLineIndex );
}

- (void)twoDGraphView:(SM2DGraphView *)inGraphView willDisplayBarIndex:(unsigned int)inBarIndex forLineIndex:(unsigned int)inLineIndex withAttributes:(NSMutableDictionary *)attr;
{
	
}

- (IBAction)changeTotalSize:(id)sender
{
    [self refreshUserGraphView];
}

@end
