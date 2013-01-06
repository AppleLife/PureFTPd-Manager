/*
 *  NSNavBrowserCell.h
 *  gDisk
 *
 *  Created by Wagner Marie on 03/02/2006.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */
 
#import <Cocoa/Cocoa.h>

@interface NSNavBrowserCell : NSBrowserCell

+ (void) delayedProcessGetInfoButtonClick: (id) parameter1;
+ (void) delayedProcessLogonButtonClick: (id) parameter1;
+ (NSSize) iconSize;
+ (char) preprefersTrackingUntilMouseUp;
+ (void) resetDateFormats;

- (NSRect) _branchImageRectForBounds: (NSRect) parameter1;
- (void) _createNewNodePreviewHelper;
- (id) _currentBranchImage;
- (void) _drawBackgroundWithFrame: (NSRect) parameter1 inView: (id) parameter2;
- (void) _drawHighlightWithFrame: (NSRect) parameter1 inView: (id) parameter2;
- (void) _drawLabelHighlightIfNecessaryWithFrame: (NSRect) parameter1 inView: (id) parameter2 fullHighlight: (char) parameter3;
- (int) _effectiveFocusRingType;
- (void) _handleChildChanged: (id) parameter1;
- (void) _releaseNodePreviewHelper;
- (id) _textAttributes;
- (int) _typesetterBehavior;
- (char) _usingAlternateHighlightColorWithFrame: (NSRect) parameter1 inView: (id) parameter2;
- (NSRect) buttonRectForBounds: (NSRect) parameter1;
- (void) calcDrawInfo: (NSRect) parameter1;
- (void) cancelDelayedUpdate;
- (NSSize) cellSizeForBounds: (NSRect) parameter1;
- (NSRect) clickableContentRectForBounds: (NSRect) parameter1;
- (char) controlDrawsSelectionHighlights;
- (id) controlView;
- (id) copyWithZone: (void*) parameter1;
- (id) currentButtonCell;
- (void) currentButtonClicked: (id) parameter1;
- (void) dealloc;
- (void) doCalcDrawInfo: (NSRect) parameter1;
- (void) drawInteriorWithFrame: (NSRect) parameter1 inView: (id) parameter2;
- (void) drawNormalInteriorWithFrame: (NSRect) parameter1 inView: (id) parameter2;
- (void) drawPreviewInteriorWithFrame: (NSRect) parameter1 inView: (id) parameter2;
- (void) finalize;
- (id) getInfoButtonCell;
- (void) handleDelayedUpdate: (id) parameter1;
- (void) handlePreviewTextUpdate;
- (char) hasNodeLabel;
- (id) init;
- (char) isDirectory;
- (char) isFauxDisabled;
- (char) isPreview;
- (id) logonButtonCell;
- (id) node;
- (void) scheduleDelayedUpdate;
- (void) setControlView: (id) parameter1;
- (void) setEnableSelectionHighlightDrawing: (char) parameter1;
- (void) setEnableTextHighlightDrawing: (char) parameter1;
- (void) setNode: (id) parameter1 isDirectory: (char) parameter2 displayState: (int) parameter3;
- (void) setPreviewNode: (id) parameter1;
- (void) setShowsGetInfoButton: (char) parameter1;
- (void) setShowsLogonButton: (char) parameter1;
- (char) showsGetInfoButton;
- (char) showsLogonButton;
- (void) startObservingPreviewNode: (id) parameter1;
- (void) stopObservingPreviewNode;
- (NSRect) titleRectForBounds: (NSRect) parameter1;
- (char) trackMouse: (id) parameter1 inRect: (NSRect) parameter2 ofView: (id) parameter3 untilMouseUp: (char) parameter4;
- (char) wantsToTrackMouseForEvent: (id) parameter1 inRect: (NSRect) parameter2 ofView: (id) parameter3;

@end

@interface NSNavBrowserCell(NSNavBrowserCellRevealovers)

- (void) _drawRevealoverWithFrame: (NSRect) parameter1 inView: (id) parameter2 forView: (id) parameter3;
- (char) _needsRevealoverWithFrame: (void*) parameter1 trackingRect: (void*) parameter2 inView: (id) parameter3;
- (void) drawRevealoverTextWithFrame: (NSRect) parameter1 inView: (id) parameter2 forView: (id) parameter3;

@end