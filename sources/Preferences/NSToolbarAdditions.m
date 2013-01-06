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

#import "NSToolbarAdditions.h"
#import <Foundation/Foundation.h>

@implementation NSToolbar (NSToolbarCustomizableAdditions)
- (BOOL) alwaysCustomizableByDrag {
    return (BOOL) _tbFlags.clickAndDragPerformsCustomization;
}

- (void) setAlwaysCustomizableByDrag:(BOOL) flag {
	_tbFlags.clickAndDragPerformsCustomization = (unsigned int) flag & 1;
}

- (BOOL) showsContextMenu {
	return (BOOL) ! _tbFlags.showsNoContextMenu;
}

- (void) setShowsContextMenu:(BOOL) flag {
	_tbFlags.showsNoContextMenu = (unsigned int) ! flag & 1;
}

- (unsigned int) indexOfFirstMovableItem {
	return (unsigned int) _tbFlags.firstMoveableItemIndex;
}

- (void) setIndexOfFirstMovableItem:(unsigned int) anIndex {
	_tbFlags.firstMoveableItemIndex = (unsigned int) anIndex & 0x3F;
}
@end