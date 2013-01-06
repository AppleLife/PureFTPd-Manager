/*
    Copyright (c) 2003, Stephane Sudre
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted
    provided that the following conditions are met:

	Redistributions of source code must retain the above copyright notice, this list of conditions
    and the following disclaimer.

	Redistributions in binary form must reproduce the above copyright notice, this list of conditions
    and the following disclaimer in the documentation and/or other materials provided with the distribution.

	Neither the name of the WhiteBox nor the names of its contributors may be used to endorse 
    or promote products derived from this software without specific prior written permission.


	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
    IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
    CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "AKListView.h"

#define AKLISTVIEW_LINEHEIGHT	19
#define AKLISTVIEW_INTERSPACE_H	5
#define AKLISTVIEW_IMAGEWIDTH	10
#define AKLISTVIEW_IMAGEHEIGHT	11

@implementation AKListView

+ (NSDictionary *) sharedFontAttributes
{
    static NSDictionary * sharedFontAttributes_=nil;
    
    if (!sharedFontAttributes_)
    {
        NSFont * tFont;
        
        tFont=[NSFont labelFontOfSize:13.0];

        if (tFont!=nil)
        {
            sharedFontAttributes_ = [[NSDictionary dictionaryWithObject:tFont forKey:NSFontAttributeName] retain];
        }
    }
    
    return sharedFontAttributes_;
}

- (id) initWithFrame:(NSRect) frame
{
    self=[super initWithFrame:frame];
    
    if (self)
    {
        currentPaneIndex_=0;
    
        unselectedPaneImage_=[NSImage imageNamed:@"unselected"];
        selectedPaneImage_=[NSImage imageNamed:@"selected"];
        unProcessedPaneImage_=[NSImage imageNamed:@"unprocessed"];
    
        array_= [[NSMutableArray array] retain];
    }
    
    return self;
}

- (void) addPaneName:(NSString *) inPaneName
{
    [array_ addObject:inPaneName];
}

- (int) currentPaneIndex
{
    return currentPaneIndex_;
}

- (void) setCurrentPaneIndex:(int) inPaneIndex
{
    currentPaneIndex_=inPaneIndex;
    [self setNeedsDisplay:YES];
}

- (void) drawRect:(NSRect) frame
{
    int i;
    int tCount=[array_ count];
    NSRect tRect=[self frame];
    NSImage * tImage;
    NSString * tString;
    NSSize tSize;
    NSDictionary * tFontAttributes=[AKListView sharedFontAttributes];
    NSRect tStringRect;
    
    tRect.origin.x=0;
    tRect.origin.y=tRect.size.height-AKLISTVIEW_LINEHEIGHT;
    
    for(i=0;(tRect.origin.y>=0 && i<tCount);i++)
    {
        // Draw the Button
        
        tImage = ((i==currentPaneIndex_) ? selectedPaneImage_ : ((i < currentPaneIndex_) ? unselectedPaneImage_ : unProcessedPaneImage_));
        
        [tImage compositeToPoint:NSMakePoint(tRect.origin.x,tRect.origin.y+(AKLISTVIEW_LINEHEIGHT-AKLISTVIEW_IMAGEHEIGHT)*0.5) operation:NSCompositeSourceOver];
        
        // Draw the PaneTitle
        
        tString = [array_ objectAtIndex:i];
        
        tSize = [tString sizeWithAttributes:tFontAttributes];
        
        tStringRect=tRect;
        tStringRect.origin.x=AKLISTVIEW_IMAGEWIDTH+AKLISTVIEW_INTERSPACE_H;
        tStringRect.origin.y=tStringRect.origin.y+(AKLISTVIEW_LINEHEIGHT-tSize.height)*0.5;
        tStringRect.size=tSize;
        
        [tString drawInRect:tStringRect withAttributes:tFontAttributes];
        
        tRect.origin.y-=AKLISTVIEW_LINEHEIGHT;
    }
}

@end
