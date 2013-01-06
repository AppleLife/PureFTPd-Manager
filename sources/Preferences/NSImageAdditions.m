/*
 PureFTPd Manager
 Copyright (C) 2003-2004 Jean-Matthieu Schaffhauser <jean-matthieu@users.sourceforge.net>
 
 THIS CODE HAS BEEN BORROWED FROM FIRE.APP (at least I think so)
 I Can't find the guys who coded that in the first place ... If you know, let me know.
 
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

#import "NSImageAdditions.h"
#import <Cocoa/Cocoa.h>

@implementation NSImage (NSImageAdditions)
- (void) drawFlippedInRect:(NSRect) rect operation:(NSCompositingOperation) op fraction:(float) delta {
	CGContextRef context;

	context = [[NSGraphicsContext currentContext] graphicsPort];
	CGContextSaveGState( context ); {
		CGContextTranslateCTM( context, 0, NSMaxY( rect ) );
		CGContextScaleCTM( context, 1, -1 );

		rect.origin.y = 0;
		[self drawInRect:rect fromRect:NSZeroRect operation:op fraction:delta];
	} CGContextRestoreGState( context );
}

- (void) drawFlippedInRect:(NSRect) rect operation:(NSCompositingOperation) op {
    [self drawFlippedInRect:rect operation:op fraction:1.0];
}

- (void)applyBadge:(NSImage*)badge withAlpha:(float)alpha scale:(float)scale
{
    NSImage *newBadge;
    if (!badge)
        return;
    
    newBadge = [[badge copy] autorelease];
    [newBadge setScalesWhenResized:YES];
    [newBadge setSize:NSMakeSize([self size].width * scale,[self size].height * scale)];
    
    [self lockFocus];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [newBadge dissolveToPoint:NSMakePoint([self size].width - [newBadge size].width,0) fraction:alpha];
    [self unlockFocus];
}

@end
