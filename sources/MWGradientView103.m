//
//  MWGradientView103.m
//  PureFTP
//
//  Created by Jean-Matthieu Schaffhauser on 15/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MWGradientView103.h"


#import "defines.h"

@implementation MWGradientView


- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setDefaults];
    }
    return self;
}


- (void)dealloc
{
    [backgroundColor release];
    [super dealloc];
}

- (void)setDefaults
{
	useGradient = NO;
	Gestalt(gestaltSystemVersion, &MacVersion);
	
	[self setBackgroundColor:[NSColor clearColor]];
	[self setDrawsGradientBackground:NO];
}


- (void)awakeFromNib
{
    // For when we've been created in a nib file
    [self setDefaults];
}


- (BOOL)preservesContentDuringLiveResize
{
    // NSBox returns YES for this, but doing so would screw up the gradients.
    return NO;
}


- (void)drawRect:(NSRect)rect {
	
    // Construct rounded rect path
    NSRect boxRect = [self bounds];
    NSRect bgRect = boxRect;
    int minX = NSMinX(bgRect);
    int maxX = NSMaxX(bgRect);
    int minY = NSMinY(bgRect);
    int maxY = NSMaxY(bgRect);
    NSBezierPath *bgPath = [NSBezierPath bezierPathWithRect:bgRect];
	
	// Draw solid color background
	[backgroundColor set];
	[bgPath fill];

}


- (NSColor *)backgroundColor
{
    return backgroundColor;
}


- (void)setBackgroundColor:(NSColor *)newBackgroundColor
{
    [newBackgroundColor retain];
    [backgroundColor release];
    backgroundColor = newBackgroundColor;
	[self display];
}


- (void)setDrawsGradientBackground:(BOOL)newDrawsGradientBackground
{
	drawsGradientBackground = NO;
	
	[self display];
}
@end
