//
//  MWGradientView103.h
//  PureFTP
//
//  Created by Jean-Matthieu Schaffhauser on 15/05/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface MWGradientView : NSView {
    NSColor *backgroundColor;
   
    BOOL drawsGradientBackground;
	//BOOL gradientPref;
	BOOL useGradient;
	SInt32 MacVersion; 
}

- (void)setDefaults;

- (NSColor *)backgroundColor;
- (void)setBackgroundColor:(NSColor *)newBackgroundColor;
- (void)setDrawsGradientBackground:(BOOL)newDrawsGradientBackground;

@end
