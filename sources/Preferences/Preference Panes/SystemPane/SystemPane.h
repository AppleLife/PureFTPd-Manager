#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import <Foundation/Foundation.h>

@class PureController;

@interface SystemPane : NSPreferencePane
{
    IBOutlet NSButton *managerUpdateSwitch;
    IBOutlet NSTextField *rdvField;
    IBOutlet NSButton *rdvSwitch;
    IBOutlet NSButton *startupSwitch;
    IBOutlet NSPopUpButton *serverModePopUp;
    IBOutlet NSTextField *userBaseDirField;
    IBOutlet NSTextField *vhostBaseDirField;
   
    
    NSMutableDictionary *pureFTPPreferences;
    BOOL modified;
	int oldServerMode;
}

-(void)loadPreferences;
-(void)savePreferences;
- (IBAction)didModify:(id)sender;
- (IBAction)toggleStartup:(id)sender;
- (IBAction)chooseDir:(id)sender;

- (NSMutableArray *)generateArguments;

- (void)configureStartup;
- (void)setupXinetd;
- (void)setupStandAlone;

@end