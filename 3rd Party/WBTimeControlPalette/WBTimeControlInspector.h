//
//  WBTimeControlInspector.h
//  WBTimeControl
//
//  Created by Sean McBride on 2005-02-22.
//  Copyright Sean McBride 2005. All rights reserved.
//

#import <InterfaceBuilder/InterfaceBuilder.h>

@interface WBTimeControlInspector : IBInspector
{
	IBOutlet NSMatrix*		appearanceMatrix;
	IBOutlet NSButton*		hasSecondsButton;
	IBOutlet NSButton*		alignStepperButton;	
}
@end
