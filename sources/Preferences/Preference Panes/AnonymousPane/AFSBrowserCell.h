//
//  AFSBrowserCell.h
//
//  Copyright (c) 2001-2002, Apple. All rights reserved.
//
//  AFSBrowserCell knows how to display file system info obtained from an AFSNodeInfo object.

#import <Cocoa/Cocoa.h>

@interface AFSBrowserCell : NSBrowserCell { 
@private
    NSImage *iconImage;
}

- (void)setAttributedStringValueFromAFSNodeInfo:(AFSNodeInfo*)node;
- (void)setIconImage: (NSImage *)image;
- (NSImage*)iconImage;

@end

