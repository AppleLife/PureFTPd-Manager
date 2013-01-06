//
//  WBTimeControlPalette.h
//  WBTimeControl
//
//  Created by Sean McBride on 2005-02-22.
//  Copyright Sean McBride 2005 . All rights reserved.
//

#import <InterfaceBuilder/InterfaceBuilder.h>
#import "WBTimeControl.h"

@interface WBTimeControlPalette : IBPalette
{
	IBOutlet WBTimeControl*		control;
}
@end

@interface WBTimeControl (WBTimeControlPaletteInspector)
- (NSString *)inspectorClassName;
@end
