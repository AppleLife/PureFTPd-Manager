//
//  NSXTableMenu.m
//
//  NSXTableMenu.h
//  Tab Size: 3
// -----------------------------------------------------------------
//  Copyright (c) 2003 Aaron Sittig. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or
//  without modification, are permitted provided that the
//  following conditions are met:
//
//  1 Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  2 Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with distribution.
//  3 Neither the name of Aaron Sittig nor the names of contributors
//    may be used to endorse or promote products derived from this
//    software without specific prior written permission.
//  -----------------------------------------------------------------

#import "NSXTableMenu.h"

// We derive from NSPopUpButtonCell to retain behavior but
// modify the appearance to match the table header bar
@interface PPopUpHeaderCell : NSPopUpButtonCell {}
@end

// We create a static NSTableHeaderCell instance to draw for us
static NSTableHeaderCell* sHeaderCell = nil;

@implementation PPopUpHeaderCell

- (void)drawWithFrame:(NSRect)frame inView:(NSView *)view
{
    NSPoint	flippedPoint = frame.origin;
    
    // Flip Point to draw Icon
    if( [view isFlipped] )
        flippedPoint.y += frame.size.height;
    
    // Create NSTableHeaderCell if needed
    if( !sHeaderCell )
        sHeaderCell = [[NSTableHeaderCell alloc] initTextCell:@""];
    
    // Draw Background with NSTableHeaderCell
    [sHeaderCell drawWithFrame:frame inView:view];
    
    // Draw Table Menu Icon if Menu Attached
    if( [self menu] )
        [[NSImage imageNamed:@"tablemenu"] compositeToPoint:flippedPoint operation:NSCompositeSourceOver];
}

@end

#pragma mark -

@implementation NSTableView (NSXTableMenu)

// Since this control is really an NSPopUpButton in pull-down form
// you have to remember that the first menu item is usually
// displayed as the pull-down title but here is unused
- (NSMenu*)tableMenu
{
    // Return Menu only if PopUpButton is Installed
    if( [[self cornerView] class] == [NSPopUpButton class] )
        return [(NSPopUpButton*)[self cornerView] menu];
    
    // No Menu Installed
    return nil;
}

- (void)setTableMenu:(NSMenu*)menu
{
    NSPopUpButton*		menuPopUp;
    
    // Install Menu PopUp
    if( [[self cornerView] class] != [NSPopUpButton class] )
    {
        // Create Vanilla PopUp Button
        menuPopUp = [[[NSPopUpButton alloc] init] autorelease];
        
        // Convert to HeaderCell looking Pull-Down with Custom Cell
        [menuPopUp setCell:[[[PPopUpHeaderCell alloc] initTextCell:@"" pullsDown:YES] autorelease]];
        
        // Stick in TableView Corner
        [self setCornerView:menuPopUp];
    }
    else
        // Otherwise, Get Existing Menu PopUp
        menuPopUp = (NSPopUpButton*)[self cornerView];
    
    // Update PopUp Menu
    [menuPopUp setMenu:menu];
    
    // Refresh to Show/Hide Icon
    [menuPopUp display];
}

@end
