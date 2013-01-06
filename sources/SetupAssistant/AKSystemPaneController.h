/* AKSystemPaneController */

#import <Cocoa/Cocoa.h>
#import "AKPaneController.h"

@interface AKSystemPaneController : AKPaneController
{
    IBOutlet NSButton *rdvSwitch;
	IBOutlet NSButton *pamSwitch;
    IBOutlet NSButton *startupSwitch;
    IBOutlet NSTextField *vuserBaseDirField;
    IBOutlet NSTextField *vhostBaseDirField;
    
}
- (IBAction)chooseDir:(id)sender;
@end
