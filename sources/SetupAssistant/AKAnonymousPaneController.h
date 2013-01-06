/* AKAnonymousPaneController */

#import <Cocoa/Cocoa.h>

#import "AKPaneController.h"

@interface AKAnonymousPaneController : AKPaneController
{
    IBOutlet NSPopUpButton *anonGroupPopUp;
    IBOutlet NSTextField *anonHomeField;
    IBOutlet NSButton *anonSkipSwitch;
    IBOutlet NSTextField *anonUIDField;
}

- (IBAction)chooseDir:(id)sender;
@end
