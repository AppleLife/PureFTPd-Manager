/*
 *  NSNavView.h
 *  gDisk
 *
 *  Created by Wagner Marie on 03/02/2006.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@class NSNavDataSource, NSNavNodePopUpButton, NSNavQuerySliceView, NSNavSidebarView, NSNavSplitViewController;

@interface NSNavView : NSView
{
	NSBrowser*                   _browser;
	NSNavDataSource*             _dataSource;
	id                           _delegate;
	id                           _delegatedObject;
	NSControl*                   _fileListModeControl;
	NSView*                      _fileListViewContainer;
	NSControl*                   _historyControl;
	NSOutlineView*               _outline;
	NSNavNodePopUpButton*        _pathComponentPicker;
	char                         _restoredSavedSettings;
	NSSearchField*               _searchField;
	NSProgressIndicator*         _searchProgressIndicator;
	NSRect                       _searchProgressIndicatorFrame;
	NSTextField*                 _searchResultsCountField;
	NSNavQuerySliceView*         _searchSliceView;
	char                         _showingSearchParts;
	NSNavSidebarView*            _sidebar;
	NSNavSplitViewController*    _splitViewController;
}

+ (id) navView;

- (id) _activeFileListViewForResizing;
- (void) _addCurrentDirectoryToRecentPlaces;
- (void) _beginDrawView: (id) parameter1;
- (id) _bottomContainerView;
- (char) _cachingView;
- (void) _changeFileListMode: (id) parameter1;
- (void) _changeHistory: (id) parameter1;
- (void) _commonHandleRootOrCurrentDirectoryChanged;
- (void) _concludeDefaultKeyLoopComputation;
- (void) _configureFileListModeControlForMode: (int) parameter1;
- (void) _configureForFileListMode: (int) parameter1;
- (void) _configureForShowingInPanel;
- (void) _configureHistoryControl;
- (void) _configurePathComponentPicker;
- (void) _configureSearching: (char) parameter1;
- (id) _dataSource;
- (id) _delegatedObject;
- (void) _directoryPopUpButtonClick: (id) parameter1;
- (char) _drawView: (id) parameter1;
- (char) _dropNode: (id) parameter1;
- (void) _endDrawView: (id) parameter1;
- (id) _fileListModeControlCell;
- (void) _handleAppActivation: (id) parameter1;
- (void) _handleCurrentBrowsingNodePathChanged;
- (void) _handleCurrentDirectoryNodeChanged;
- (void) _handleFauxDisabledNodeClicked: (id) parameter1;
- (void) _handleFileListDidReloadChildrenForNode: (id) parameter1;
- (void) _handleFileListModeChanged;
- (void) _handleQueryStateChange: (id) parameter1;
- (void) _handleRootNodeChanged;
- (void) _handleSelectionChanged;
- (void) _handleSelectionConfirmed;
- (void) _hideQueryProgress;
- (id) _historyControlCell;
- (void) _positionAndResizeSearchParts;
- (id) _recentPlacesNode;
- (void) _registerForQueryStateChangeNotifications: (id) parameter1;
- (void) _searchFieldAction: (id) parameter1;
- (void) _searchFieldCancelAction: (id) parameter1;
- (void) _selectFirstKeyView;
- (void) _setDelegate: (id) parameter1 forPanel: (id) parameter2;
- (void) _setupFileListModeControl;
- (void) _setupHistoryControl;
- (void) _setupSearchParts;
- (id) _setupSegmentSwitchForControl: (id) parameter1 firstImage: (id) parameter2 secondImage: (id) parameter3 action: (SEL) parameter4;
- (void) _showQueryProgress;
- (id) _sidebarView;
- (void) _swapFileListKeyViewFrom: (id) parameter1 to: (id) parameter2;
- (id) _topContainerView;
- (void) _unregisterForQueryStateChangeNotifications: (id) parameter1;
- (char) allowsExpandingMultipleDirectories;
- (char) allowsMultipleSelection;
- (void) awakeFromNib;
- (char) calculatesAllSizes;
- (char) canChooseDirectories;
- (char) canChooseFiles;
- (char) canClickDisabledFiles;
- (void) clockPreferencesChanged: (id) parameter1;
- (id) currentDirectoryNode;
- (id) currentResolvedDirectoryNode;
- (void) dealloc;
- (id) delegate;
- (id) displayedFileProperties;
- (id) enabledFileTypes;
- (id) fauxFilePackageTypes;
- (int) fileListMode;
- (id) fileListOrderedByFileProperty;
- (void) finalize;
- (char) goBackwardInHistoryIfPossible;
- (char) goForwardInHistoryIfPossible;
- (void) goUpDirectory;
- (id) initWithFrame: (NSRect) parameter1;
- (char) isFileListOrderedAscending;
- (char) isFileListOrderedCaseSensitive;
- (char) isFilePropertyDisplayed: (id) parameter1;
- (id) lazyGetChildrenForNodeWithIdentifier: (id) parameter1;
- (Class) navNodeClass;
- (char) performKeyEquivalent: (id) parameter1;
- (char) preservesContentDuringLiveResize;
- (void) reloadRootNode;
- (void) resizeSubviewsWithOldSize: (NSSize) parameter1;
- (char) resolvesAliases;
- (id) rootNode;
- (id) selectedNodes;
- (id) selectedResolvedNodes;
- (void) setAllowsExpandingMultipleDirectories: (char) parameter1;
- (void) setAllowsMultipleSelection: (char) parameter1;
- (void) setCalculatesAllSizes: (char) parameter1;
- (void) setCanChooseDirectories: (char) parameter1;
- (void) setCanChooseFiles: (char) parameter1;
- (void) setCanClickDisabledFiles: (char) parameter1;
- (void) setCurrentDirectoryNode: (id) parameter1;
- (void) setDelegate: (id) parameter1;
- (void) setEnabledFileTypes: (id) parameter1;
- (void) setFauxFilePackageTypes: (id) parameter1;
- (void) setFileListMode: (int) parameter1;
- (void) setFileListOrderedByFileProperty: (id) parameter1;
- (void) setIsFileListOrderedAscending: (char) parameter1;
- (void) setIsFileListOrderedCaseSensitive: (char) parameter1;
- (void) setIsFileProperty: (id) parameter1 displayed: (char) parameter2;
- (void) setNavNodeClass: (Class) parameter1;
- (void) setResolvesAliases: (char) parameter1;
- (void) setRootNode: (id) parameter1;
- (void) setRootPath: (id) parameter1;
- (char) setSelectionFromDroppedNode: (id) parameter1 selectionHelper: (id) parameter2;
- (char) setSelectionFromPasteboard: (id) parameter1 selectionHelper: (id) parameter2;
- (void) setShowsHiddenFiles: (char) parameter1;
- (void) setShowsPreviews: (char) parameter1;
- (void) setTreatsDirectoryAliasesAsDirectories: (char) parameter1;
- (void) setTreatsFilePackagesAsDirectories: (char) parameter1;
- (id) showNodeInCurrentDirectoryWithDisplayNamePrefix: (id) parameter1 selectIfEnabled: (char) parameter2;
- (id) showNodeInCurrentDirectoryWithFilename: (id) parameter1 selectIfEnabled: (char) parameter2;
- (char) showsHiddenFiles;
- (char) showsPreviews;
- (void) tileVertically;
- (char) treatsDirectoryAliasesAsDirectories;
- (char) treatsFilePackagesAsDirectories;
- (id) visualRootNode;

@end

