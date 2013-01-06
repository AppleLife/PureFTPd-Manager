/* AKVUPaneController */

#import <Cocoa/Cocoa.h>

#import "AKPaneController.h"

@interface AKVUPaneController : AKPaneController
{
    IBOutlet NSPanel *infoPanel;
    IBOutlet NSTextField *vuserGIDField;
    IBOutlet NSTextField *vuserGroupField;
    IBOutlet NSTextField *vuserLoginField;
    IBOutlet NSTextField *vuserUIDField;
    IBOutlet NSButton *vuserSkipSwitch;
}

@end
