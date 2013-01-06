/* FTPLogPane */

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import <Foundation/Foundation.h>
#import "defines.h"
#import "WBTimeControl.h"

@class PureController;

@interface FTPLogPane : NSPreferencePane
{
    IBOutlet NSButton *browseButton;
    IBOutlet NSPopUpButton *formatPopUp;
    IBOutlet NSTextField *locationField;
    IBOutlet NSButton *logSwitch;
    IBOutlet NSButton *updateSwitch;
    IBOutlet NSButton *shareSwitch;
    
	IBOutlet NSButton *convertSwitch;
	IBOutlet NSButton *browseDirButton;
	IBOutlet NSButton *detailOutputSwitch;
	IBOutlet NSButton *previewButton;
	IBOutlet NSPopUpButton *daysPopUp;
	IBOutlet NSPopUpButton *statFormatPopUp;
	IBOutlet NSTextField *saveToField;
	
	IBOutlet WBTimeControl *time;
    
    NSMutableDictionary *pureFTPPreferences;
    BOOL modified;
	int initialLogFormat;
	NSString *initialLogLocation;
}

-(void)loadPreferences;
-(void)savePreferences;

- (IBAction)chooseFile:(id)sender;
- (IBAction)didModify:(id)sender;

- (IBAction)chooseDir:(id)sender;
- (IBAction)preview:(id)sender;
- (IBAction)toggleConvertion:(id)sender;

- (void)updateCronEntry;
@end
