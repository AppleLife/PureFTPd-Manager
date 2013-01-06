/*
 *  NSNavFBENode.h
 *  gDisk
 *
 *  Created by Wagner Marie on 03/02/2006.
 *  Copyright 2006 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>

@interface NSNavFBENode : NSNavNode
{
	void*    _fbeNode;
}

+ (void) _postNotificationForEvent: (unsigned long) parameter1 notificationName: (id) parameter2 parent: (id) parameter3;
+ (void) _postNotificationForEvent: (unsigned long) parameter1 notificationName: (id) parameter2 parent: (id) parameter3 child: (id) parameter4;
+ (void) _postNotificationForEvent: (unsigned long) parameter1 notificationName: (id) parameter2 parent: (id) parameter3 child: (id) parameter4 fbeProperty: (int) parameter5;
+ (void) _processNotifications: (id) parameter1;
+ (void) _reallyProcessNotifications: (id) parameter1;
+ (void*) eventQueue;
+ (id) findSidebarNodeForNode: (id) parameter1;
+ (id) iDiskNode;
+ (void) initialize;
+ (id) navNodeWithSimpleQueryString: (id) parameter1 searchScopeNode: (id) parameter2;
+ (id) nodeWithFBENode: (void*) parameter1;
+ (id) nodeWithPath: (id) parameter1;
+ (Class) previewHelperClass;
+ (id) sidebarContainerNodes;
+ (char) supportsMutableFBENode;
+ (id) topLevelNode;
+ (id) userHomeNode;

- (void) _calculatePreviewThumbnailImage: (id*) parameter1 allowComputingFromFullImage: (char) parameter2;
- (short) _labelColorIndex;
- (id) _labelPatternColorForLabelIndex: (short) parameter1;
- (void) _registerForChildChangedNotifications;
- (char) _registeredForChildNotifications;
- (void) _setRegisteredForChildNotifications: (char) parameter1;
- (void) _unregisterForChildChangedNotifications;
- (char) canVolumeBeUnmounted;

- (id) children;
- (id) comment;
- (void*) copyIcon;
- (void*) copyPreviewIcon;
- (id) copyWithZone: (void*) parameter1;
- (id) creationDate;
- (void) dealloc;
- (id) description;
- (void) didPostNotificationForNodeEventKind: (unsigned long) parameter1 notification: (id) parameter2;
- (id) displayName;
- (char) eject;
- (char) ejectVolume;
- (id) fastGetPreviewThumbnailImage;
- (void*) fbeNode;
- (id) fileType;
- (void) finalize;
- (id) finderPath;
- (void) flushAllCaches;

- (id) getNodeAsDeepResolvedNode: (char) parameter1;
- (id) getNodeAsInfoNode: (char) parameter1;
- (id) getNodeAsResolvedNode: (char) parameter1;
- (unsigned int) hash;
- (id) initWithFBENode: (void*) parameter1;
- (id) initWithPath: (id) parameter1;
- (id) initWithPath: (id) parameter1 logonOK: (char) parameter2;
- (char) isAlias;
- (char) isContainer;
- (char) isDisconnectedMountPoint;
- (char) isEjectable;
- (char) isEqual: (id) parameter1;
- (char) isExtensionHidden;
- (char) isPackage;
- (char) isUnauthenticatedMountPoint;
- (char) isValid;
- (char) isVisible;
- (char) isVolume;
- (char) isVolumeEjectable;
- (char) isVolumeLocal;
- (id) kind;
- (id) labelColor;

- (id) modDate;
- (id) name;
- (id) parent;
- (id) path;

- (id) previewThumbnailImage;
- (void) registerForPropertyChangedNotifications;
- (id) searchScopeDisplayName;
- (void) setFBENode: (void*) parameter1;
- (id) shortVersion;
- (void) sync;
- (void) unregisterForPropertyChangedNotifications;

- (id) utiAsString;

@end

