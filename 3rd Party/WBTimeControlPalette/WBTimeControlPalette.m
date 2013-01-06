//
//  WBTimeControlPalette.m
//  WBTimeControl
//
//  Created by Sean McBride on 2005-02-22.
//  Copyright Sean McBride 2005 . All rights reserved.
//

#import "WBTimeControlPalette.h"

@implementation WBTimeControlPalette

- (void)finishInstantiate
{
    /* `finishInstantiate' can be used to associate non-view objects with
     * a view in the palette's nib.  For example:
     *   [self associateObject:aNonUIObject ofType:IBObjectPboardType
     *                withView:aView];
     */
}

@end

@implementation WBTimeControl (WBTimeControlPaletteInspector)

- (NSString *)inspectorClassName
{
    return @"WBTimeControlInspector";
}

@end
