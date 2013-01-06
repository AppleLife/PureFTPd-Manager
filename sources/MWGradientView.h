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

#import <Cocoa/Cocoa.h>
#import <QuartzCore/CoreImage.h> // needed for Core Image

@interface MWGradientView : NSView {
    NSColor *gradientStartColor;
    NSColor *gradientEndColor;
    NSColor *backgroundColor;
   
    BOOL drawsGradientBackground;
	//BOOL gradientPref;
	BOOL useGradient;
	SInt32 MacVersion; 
}

- (void)setDefaults;

- (NSColor *)gradientStartColor;
- (void)setGradientStartColor:(NSColor *)newGradientStartColor;
- (NSColor *)gradientEndColor;
- (void)setGradientEndColor:(NSColor *)newGradientEndColor;
- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)newBackgroundColor;
- (BOOL)drawsGradientBackground;
- (void)setDrawsGradientBackground:(BOOL)newDrawsGradientBackground;

@end
