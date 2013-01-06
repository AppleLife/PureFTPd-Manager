//
//  RoundedBox.m
//  RoundedBox
//
//  Created by Matt Gemmell on 01/11/2005.
//  Copyright 2005 Matt Gemmell. http://mattgemmell.com/
//
//  Permission to use this code:
//
//  Feel free to use this code in your software, either as-is or 
//  in a modified form. Either way, please include a credit in 
//  your software's "About" box or similar, mentioning at least 
//  my name (Matt Gemmell). A link to my site would be nice too.
//
//  Permission to redistribute this code:
//
//  You can redistribute this code, as long as you keep these 
//  comments. You can also redistribute modified versions of the 
//  code, as long as you add comments to say that you've made 
//  modifications (keeping these original comments too).
//
//  If you do use or redistribute this code, an email would be 
//  appreciated, just to let me know that people are finding my 
//  code useful. You can reach me at matt.gemmell@gmail.com
//

#import "MWGradientView.h"
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
    [gradientStartColor release];
    [gradientEndColor release];
    [backgroundColor release];
    
    [super dealloc];
}

- (void)setDefaults
{
	useGradient = NO;
	Gestalt(gestaltSystemVersion, &MacVersion);
	
	[self setBackgroundColor:[NSColor clearColor]];
	[self setDrawsGradientBackground:NO];
	
	NSDictionary *pref = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
	id value = [pref objectForKey:PureFTPGradient];
	if ((value == nil) || ([value intValue] == 1))
		useGradient=YES;
	
	if (MacVersion >= 0x1040 && useGradient){
		//[NSColor colorWithCalibratedRed:0.8235 green:0.8235 blue:0.8235 alpha:1.0]
		//[NSColor colorWithCalibratedRed:0.7235 green:0.7235 blue:0.7235 alpha:1.0]
		
		[self setGradientStartColor:[NSColor colorWithCalibratedRed:0.8430 green:0.8430 blue:0.8430 alpha:1.0]];
		[self setGradientEndColor:[NSColor clearColor]];
		[self setDrawsGradientBackground:YES];
	}
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
	
	// Draw background
    if ([self drawsGradientBackground]) {
        // Draw gradient background using Core Image
        
        // Wonder if there's a nicer way to get a CIColor from an NSColor...
        CIColor* startColor = [CIColor colorWithRed:[gradientStartColor redComponent] 
                                              green:[gradientStartColor greenComponent] 
                                               blue:[gradientStartColor blueComponent] 
                                              alpha:[gradientStartColor alphaComponent]];
        CIColor* endColor = [CIColor colorWithRed:[gradientEndColor redComponent] 
                                            green:[gradientEndColor greenComponent] 
                                             blue:[gradientEndColor blueComponent] 
                                            alpha:[gradientEndColor alphaComponent]];
        
        CIFilter *myFilter = [CIFilter filterWithName:@"CILinearGradient"];
        [myFilter setDefaults];
        [myFilter setValue:[CIVector vectorWithX:(minX) 
                                               Y:(minY)] 
                    forKey:@"inputPoint0"];
        [myFilter setValue:[CIVector vectorWithX:(minX) 
                                               Y:(maxY)] 
                    forKey:@"inputPoint1"];
        [myFilter setValue:startColor 
                    forKey:@"inputColor0"];
        [myFilter setValue:endColor 
                    forKey:@"inputColor1"];
        CIImage *theImage = [myFilter valueForKey:@"outputImage"];
        
        
        // Get a CIContext from the NSGraphicsContext, and use it to draw the CIImage
        CGRect dest = CGRectMake(minX, minY, maxX - minX, maxY - minY);
        
        CGPoint pt = CGPointMake(bgRect.origin.x, bgRect.origin.y);
        
        NSGraphicsContext *nsContext = [NSGraphicsContext currentContext];
        [nsContext saveGraphicsState];
        
        [bgPath addClip];
        
        [[nsContext CIContext] drawImage:theImage 
                                 atPoint:pt 
                                fromRect:dest];
        
        [nsContext restoreGraphicsState];
    } else {
        // Draw solid color background
        [backgroundColor set];
        [bgPath fill];
    }
}


- (NSColor *)gradientStartColor
{
    return gradientStartColor;
}


- (void)setGradientStartColor:(NSColor *)newGradientStartColor
{
    // Must ensure gradient colors are in NSCalibratedRGBColorSpace, or Core Image gets angry.
    NSColor *newCalibratedGradientStartColor = [newGradientStartColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    [newCalibratedGradientStartColor retain];
    [gradientStartColor release];
    gradientStartColor = newCalibratedGradientStartColor;
    if ([self drawsGradientBackground]) {
        [self display];
    }
}


- (NSColor *)gradientEndColor
{
    return gradientEndColor;
}


- (void)setGradientEndColor:(NSColor *)newGradientEndColor
{
    // Must ensure gradient colors are in NSCalibratedRGBColorSpace, or Core Image gets angry.
    NSColor *newCalibratedGradientEndColor = [newGradientEndColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
    [newCalibratedGradientEndColor retain];
    [gradientEndColor release];
    gradientEndColor = newCalibratedGradientEndColor;
    if ([self drawsGradientBackground]) {
        [self display];
    }
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
    if (![self drawsGradientBackground]) {
        [self display];
    }
}


- (BOOL)drawsGradientBackground
{
    return drawsGradientBackground;
}


- (void)setDrawsGradientBackground:(BOOL)newDrawsGradientBackground
{
	if (MacVersion >= 0x1040 && useGradient){
		drawsGradientBackground = newDrawsGradientBackground;
	} else {
		drawsGradientBackground = NO;
	}
	
	[self display];
    
}


@end
