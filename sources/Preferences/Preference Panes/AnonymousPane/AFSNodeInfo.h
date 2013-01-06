//
//  AFSNodeInfo.h
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
//
//  AFSNodeInfo encapsulates information about a file or directory.
//  This implementation is not necessarily the best way to do something like this,
//  it is simply a wrapper to make the rest of the browser code easy to follow.

#import <Cocoa/Cocoa.h>

@interface AFSNodeInfo : NSObject {
@private
    NSString    *relativePath;  // Path relative to the parent.
    AFSNodeInfo  *parentNode;	// Containing directory, not retained to avoid retain/release cycles.
}

+ (AFSNodeInfo *)nodeWithParent:(AFSNodeInfo*)parent atRelativePath:(NSString *)path;

- (id)initWithParent:(AFSNodeInfo*)parent atRelativePath:(NSString*)path;

- (void)dealloc;

- (NSArray *)subNodes;
- (NSArray *)visibleSubNodes;

- (NSString *)fsType;
- (NSString *)absolutePath;
- (NSString *)lastPathComponent;

- (BOOL)isLink;
- (BOOL)isDirectory;

- (BOOL)isReadable;
- (BOOL)isVisible;

- (NSImage*)iconImageOfSize:(NSSize)size; 

@end
