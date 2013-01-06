//
//  WBTimeControlInspector.m
//  WBTimeControl
//
//  Created by Sean McBride on 2005-02-22.
//  Copyright Sean McBride 2005 . All rights reserved.
//

#import "WBTimeControlInspector.h"
#import "WBTimeControl.h"

@implementation WBTimeControlInspector

- (id)init
{
    self = [super init];
    if (self)
	{
		[NSBundle loadNibNamed:@"WBTimeControlInspector" owner:self];
	}
    return self;
}

- (void)ok:(id)sender
{
    WBTimeControl*		control = [self object];
	[control setAppearance:[[appearanceMatrix selectedCell] tag]];
	[control setShowSeconds:(BOOL)[hasSecondsButton state]];
	[control setAlignStepper:(BOOL)[alignStepperButton state]];
	[super ok:sender];
}

- (void)revert:(id)sender
{
    WBTimeControl*		control = [self object];
	[appearanceMatrix selectCellWithTag:[control appearance]];
	[hasSecondsButton setState:(int)[control showSeconds]];
	[alignStepperButton setState:(int)[control alignStepper]];
    [super revert:sender];
}

@end
