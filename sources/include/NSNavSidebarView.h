/*
 *  NSNavSidebarView.h
 *  gDisk
 *
 *  Created by Wagner Marie on 03/02/2006.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@class NSNavView, NSNavNode;

@interface NSNavSidebarView : NSControl
{
	char               _alreadyHandlingSetFrameSize;
	float              _itemViewAreaHeight;
	NSMutableArray*    _itemViewGroups;
	NSMutableArray*    _itemViewSeparators;
	float              _lastIconHeight;
	NSView*            _lastLayedView;
	float              _lastTiledContentHeight;
	float              _lastTiledItemViewHeight;
	NSNavView*         _navView;
	char               _registeredForNavChildNotifications;
	int                _rememberedSnapToIndex;
	NSNavNode*         _sidebarFavoritesNode;
	NSNavNode*         _sidebarVolumesNode;
}

+ (NSSize) defaultIconSize;

- (void) _adjustWidthsToFit;
- (id) _allSidebarItemViews;
- (void) _drawScrollViewFocusRing: (id) parameter1 clipRect: (NSRect) parameter2 needsFullDisplay: (char) parameter3;
- (void) _handleChildAddedOrRemoved: (id) parameter1;
- (void) _handleChildChanged: (id) parameter1;
- (void) _handleChildrenChanged: (id) parameter1;
- (void) _handleRedrawSidebarSelectionIfNecessary;
- (id) _itemAtPosition: (NSPoint) parameter1;
- (void) _layoutItemViewForWithItemHeight: (float) parameter1 allSidebarItemViews: (id) parameter2;
- (void) _loadItemViewsForChildrenOfContainerNodes: (id) parameter1 existingViewsToKeepTable: (id) parameter2;
- (void) _moveSelectionBy: (int) parameter1;
- (id) _orderedSidebarItemViews;
- (id) _recursiveSetDefaultKeyViewLoop;
- (void) _reloadSidebarNodes;
- (void) _setFocusRingNeedsDisplay;
- (void) _setNeedsTiling;
- (void) _setSidebarVolumesNode: (id) parameter1 favoritesNode: (id) parameter2;
- (char) _shouldDrawFocus;
- (char) _shouldDrawFocusIfInKeyWindow;
- (char) _shouldShowNode: (id) parameter1;
- (char) _showingFocusRingAroundEnclosingScrollView: (id) parameter1;
- (id) _updatedItemViewsForChildrenOfContainerNodes: (id) parameter1;
- (void) _windowChangedKeyState;
- (char) acceptsFirstResponder;
- (char) becomeFirstResponder;
- (void) clipviewBoundsChangedNotification: (id) parameter1;
- (void) dealloc;
- (void) drawRect: (NSRect) parameter1;
- (void) finalize;
- (void) getSnapToWidthList: (void*) parameter1 snapRadiusList: (void*) parameter2 count: (int*) parameter3;
- (void) handleCurrentDirectoryNodeChanged;
- (void) handleFileListModeChanged;
- (void) handleRootNodeChanged;
- (NSSize) iconSize;
- (id) initWithFrame: (NSRect) parameter1;
- (char) isFlipped;
- (char) isOpaque;
- (float) minimumWidth;
- (void) mouseDown: (id) parameter1;
- (void) moveDown: (id) parameter1;
- (void) moveUp: (id) parameter1;
- (id) navView;
- (char) needsPanelToBecomeKey;
- (int) numberOfGroups;
- (char) preservesContentDuringLiveResize;
- (int) rememberedSnapToIndex;
- (char) resignFirstResponder;
- (void) selectItem: (id) parameter1;
- (id) selectedItem;
- (void) setDisplayedContainerNodes: (id) parameter1;
- (void) setFrameSize: (NSSize) parameter1;
- (void) setKeyboardFocusRingNeedsDisplayInRect: (NSRect) parameter1;
- (void) setRememberedSnapToIndex: (int) parameter1;
- (id) sidebarFavoritesNode;
- (id) sidebarVolumesNode;
- (float) sizeToFitWidth;
- (float) spaceForScrollbarAndScrollViewBorder;
- (void) tile;
- (void) tileIfNecessary;
- (int) totalNumberOfItemViewersAndSeparators;
- (void) viewWillMoveToSuperview: (id) parameter1;

@end

@interface NSNavSidebarView(NSNavSidbarViewAccessibility)

+ (char) accessibilityIsSingleCelled;

- (id) accessibilityAttributeNames;
- (id) accessibilityDescriptionAttribute;
- (char) accessibilityIsDescriptionAttributeSettable;
- (char) accessibilityIsOrientationAttributeSettable;
- (char) accessibilityIsSelectedChildrenAttributeSettable;
- (id) accessibilityOrientationAttribute;
- (id) accessibilityRoleAttribute;
- (id) accessibilitySelectedChildrenAttribute;
- (void) accessibilitySetSelectedChildrenAttribute: (id) parameter1;

@end

@interface NSNavSidebarView(NSNavSidebarViewDragging)

- (void) draggedImage: (id) parameter1 endedAt: (NSPoint) parameter2 operation: (unsigned int) parameter3;
- (unsigned int) draggingEntered: (id) parameter1;
- (unsigned int) draggingSourceOperationMaskForLocal: (char) parameter1;
- (unsigned int) draggingUpdated: (id) parameter1;
- (char) performDragOperation: (id) parameter1;

@end


