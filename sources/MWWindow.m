//
//  MWWindow.m
//  PureFTP
//
//  Created by Jean-Matthieu Schaffhauser on 13/04/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "MWWindow.h"
#import "defines.h"
@implementation MWWindow

-(id)initWithContentRect:(NSRect)contentRect 
			   styleMask:(unsigned int)styleMask 
			     backing:(NSBackingStoreType)backingType 
				   defer:(BOOL)flag
{
	int mask = styleMask;
	
	SInt32 MacVersion; 
    Gestalt(gestaltSystemVersion, &MacVersion);
	
	NSDictionary *pref = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
	BOOL useGradient = NO;
	id value = [pref objectForKey:PureFTPGradient];
	if ((value == nil) || ([value intValue] == 1))
		useGradient=YES;
	if (MacVersion >= 0x1040 && useGradient){
		mask |= NSUnifiedTitleAndToolbarWindowMask;
	}
	
	self = [super initWithContentRect:contentRect styleMask:mask backing:backingType defer:flag];
	if (self)
	{
		
	}
	
	return self;
}



@end
