/* AKLogPaneController */

#import <Cocoa/Cocoa.h>
#import "AKPaneController.h"

@interface AKLogPaneController : AKPaneController
{
    IBOutlet NSButton *logSwitch;
    IBOutlet NSButton *prioritySwitch;
    IBOutlet NSButton *updateSwitch;
}
- (IBAction)toggleOthers:(id)sender;
@end
