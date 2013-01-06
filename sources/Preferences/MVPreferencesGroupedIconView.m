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

#import "MVPreferencesGroupedIconView.h"
#import "MVPreferencesMultipleIconView.h"
#import "MVPreferencesController.h"

@interface MVPreferencesMultipleIconView (MVPreferencesMultipleIconViewPrivate)
- (unsigned int) _numberOfRows;
@end

@interface MVPreferencesGroupedIconView (MVPreferencesGroupedIconViewPrivate)
- (unsigned int) _numberOfGroups;
- (void) _sizeToFit;
- (NSRect) _rectForGroupAtIndex:(unsigned int) index;
- (NSRect) _rectForGroupSeparatorAtIndex:(unsigned int) index;
- (void) _generateGroupViews;
- (void) _generateGroupViewAtIndex:(unsigned int) index;
@end

@implementation MVPreferencesGroupedIconView
const unsigned int groupViewHeight = 95;
const unsigned int multiIconViewYOffset = 18;
const unsigned int sideGutterWidths = 15;
const unsigned int extraRowHeight = 69;

- (id) initWithFrame:(NSRect) frame {
    if( ( self = [super initWithFrame:frame] ) ) {
		groupMultiIconViews = [[NSMutableArray array] retain];
    }
    return self;
}

- (void) drawRect:(NSRect) rect {
	[self _generateGroupViews];
}

- (void) setPreferencesController:(MVPreferencesController *) newPreferencesController {
	[preferencesController autorelease];
	preferencesController = [newPreferencesController retain];
	[self _sizeToFit];
	[self setNeedsDisplay:YES];
}

- (void) setPreferencePanes:(NSArray *) newPreferencePanes {
	[preferencePanes autorelease];
	preferencePanes = [newPreferencePanes retain];
	[self _sizeToFit];
	[self setNeedsDisplay:YES];
}

- (NSArray *) preferencePanes {
	return preferencePanes;
}

- (void) setPreferencePaneGroups:(NSArray *) newPreferencePaneGroups {
	[preferencePaneGroups autorelease];
	preferencePaneGroups = [newPreferencePaneGroups retain];
	[self _sizeToFit];
	[self setNeedsDisplay:YES];
}

- (NSArray *) preferencePaneGroups {
	return preferencePaneGroups;
}

- (BOOL) acceptsFirstResponder {
	return YES;
}

- (BOOL) becomeFirstResponder {
	[[self window] makeFirstResponder:[self viewWithTag:0]];
	return YES;
}

- (BOOL) resignFirstResponder {
	return YES;
}

- (BOOL) isFlipped {
	return YES;
}

- (BOOL) isOpaque {
	return NO;
}
@end

@implementation MVPreferencesGroupedIconView (MVPreferencesGroupedIconViewPrivate)
- (unsigned int) _numberOfGroups {
	return [[self preferencePaneGroups] count];
}

- (void) _sizeToFit {
	if( ! [self _numberOfGroups] ) return;
	if ([[[preferencesController window] contentView] canDraw])
		[self _generateGroupViews];
	[self setFrameSize:NSMakeSize( NSWidth( _bounds ), NSMaxY( [self _rectForGroupAtIndex:[self _numberOfGroups] - 1] ) ) ];
}

- (NSRect) _rectForGroupAtIndex:(unsigned int) index {
	unsigned int extra = 0, groupIndex;
	for( groupIndex = 0; groupIndex < index; groupIndex++ )
		extra += [[self viewWithTag:groupIndex] _numberOfRows] * extraRowHeight;
	return NSMakeRect( 0., (index * groupViewHeight ) + multiIconViewYOffset + index + extra, NSWidth( [self frame] ), groupViewHeight );
}

- (NSRect) _rectForGroupSeparatorAtIndex:(unsigned int) index {
	unsigned int extra = 0, groupIndex;
	if( ! index ) return NSZeroRect;
	for( groupIndex = 0; groupIndex < index; groupIndex++ )
		extra += [[self viewWithTag:groupIndex] _numberOfRows] * extraRowHeight;
	return NSMakeRect( sideGutterWidths, ((index + 1) * groupViewHeight) - groupViewHeight + index + extra, NSWidth( [self frame] ) - (sideGutterWidths * 2), 1 );
}

- (void) _generateGroupViews {
	unsigned int groupIndex, groupCount;

	groupCount = [self _numberOfGroups];
	for( groupIndex = 0; groupIndex < groupCount; groupIndex++ )
		[self _generateGroupViewAtIndex:groupIndex];
}

- (void) _generateGroupViewAtIndex:(unsigned int) index {
	MVPreferencesMultipleIconView *multiIconView = nil;
	NSString *identifier = [[preferencePaneGroups objectAtIndex:index] objectForKey:@"identifier"];
	NSString *name = NSLocalizedStringFromTable( identifier, @"MVPreferencePaneGroups", nil );
	NSDictionary *attributesDictionary;
	unsigned nameHeight = 0;

	if( ! ( multiIconView = [self viewWithTag:index] ) ) {
		NSMutableArray *panes = [NSMutableArray array];
		NSBox *sep = [[[NSBox alloc] initWithFrame:[self _rectForGroupSeparatorAtIndex:index]] autorelease];
		NSEnumerator *enumerator = [[[preferencePaneGroups objectAtIndex:index] objectForKey:@"panes"] objectEnumerator];
		id pane = nil, bundle = 0;

		multiIconView = [[[MVPreferencesMultipleIconView alloc] initWithFrame:[self _rectForGroupAtIndex:index]] autorelease];
		while( ( pane = [enumerator nextObject] ) ) {
			bundle = [NSBundle bundleWithIdentifier:pane];
			if( bundle ) [panes addObject:bundle];
		}

		[multiIconView setPreferencesController:preferencesController];
		[multiIconView setPreferencePanes:panes];
		[multiIconView setTag:index];

		[sep setBoxType:NSBoxSeparator];
		[sep setBorderType:NSBezelBorder];
	
		[self addSubview:multiIconView];
		[self addSubview:sep];
		if( index - 1 >= 0 ) [[self viewWithTag:index - 1] setNextKeyView:multiIconView];
		if( index == [self _numberOfGroups] - 1 ) [multiIconView setNextKeyView:[self viewWithTag:0]];
	}

	attributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:[NSFont boldSystemFontOfSize:13.], NSFontAttributeName, nil];
	nameHeight = [[NSFont boldSystemFontOfSize:13.] ascender];
	[name drawAtPoint:NSMakePoint( sideGutterWidths - 1, NSMinY( [multiIconView frame] ) - nameHeight - 1 ) withAttributes:attributesDictionary];
	
}
@end
