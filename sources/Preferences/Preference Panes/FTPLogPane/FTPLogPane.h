/* FTPLogPane */

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import <Foundation/Foundation.h>
#import "defines.h"

@class PureController;

@interface FTPLogPane : NSPreferencePane
{
    IBOutlet NSButton *browseButton;
    IBOutlet NSPopUpButton *formatPopUp;
    IBOutlet NSTextField *locationField;
    IBOutlet NSButton *logSwitch;
    IBOutlet NSButton *updateSwitch;
    IBOutlet NSButton *shareSwitch;
    
    NSString *lastLogFile;
    
    NSMutableDictionary *pureFTPPreferences;
    BOOL modified;
}

-(void)loadPreferences;
-(void)savePreferences;

- (IBAction)chooseFile:(id)sender;
- (IBAction)didModify:(id)sender;
@end
