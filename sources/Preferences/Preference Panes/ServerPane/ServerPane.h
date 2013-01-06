#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import <Foundation/Foundation.h>

@interface ServerPane : NSPreferencePane
{
    IBOutlet NSPopUpButton *fxpPopUpButton;
    IBOutlet NSTextField *maxSessionsField;
    IBOutlet NSTextField *maxUsersField;
    IBOutlet NSTextField *passiveRangeFromField;
    IBOutlet NSTextField *passiveRangeToField;
    IBOutlet NSTextField *portField;
    IBOutlet NSTextField *timeoutField;
    
    NSMutableDictionary *pureFTPPreferences;
    BOOL modified;
}

-(void)loadPreferences;
-(void)savePreferences;

- (IBAction)didModify:(id)sender;


@end