#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import <Foundation/Foundation.h>

@interface ServerOptionsPane : NSPreferencePane
{
    
    IBOutlet NSButton *activeModeSwitch;
    IBOutlet NSTextField *downBWField;
    IBOutlet NSTextField *extraArgField;
    IBOutlet NSTextField *ipForcedField;
	IBOutlet NSTextField *maxDepthField;
	IBOutlet NSTextField *maxFilesField;
    IBOutlet NSButton *noResolveSwitch;
    IBOutlet NSTextField *partitionField;
    IBOutlet NSTextField *upBWField;
    
    NSMutableDictionary *pureFTPPreferences;
    BOOL modified;
}

-(void)loadPreferences;
-(void)savePreferences;
- (IBAction)didModify:(id)sender;


@end