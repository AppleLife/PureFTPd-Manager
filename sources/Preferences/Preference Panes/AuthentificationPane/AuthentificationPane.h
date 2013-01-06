#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import <Foundation/Foundation.h>

@class PureController;

enum {None = 0, MySQL = 1};

@interface AuthentificationPane : NSPreferencePane
{
    IBOutlet NSTextField *authFileField;
    IBOutlet NSButton *authFileButton;
    IBOutlet NSTableView *authMethodTable;
    IBOutlet NSPopUpButton *authTypePopUp;
    IBOutlet NSWindow *authWindow;
    IBOutlet NSButton *cancelButton;
    IBOutlet NSButton *editButton;
    
    IBOutlet NSButton *createHomeSwitch;
    IBOutlet NSButton *removeAuthButton;
    
    IBOutlet NSWindow *mySQLSheet;
    
    NSMutableDictionary *pureFTPPreferences;
    NSMutableArray *authMethods;
    BOOL modified;
    
    int moreInfo;
}

-(void)loadPreferences;
-(void)savePreferences;
- (IBAction)didModify:(id)sender;

- (IBAction)addAuthMethod:(id)sender;
- (IBAction)closeAddSheet:(id)sender;
- (IBAction)chooseFile:(id)sender;
- (IBAction)removeAuthMethod:(id)sender;
- (IBAction)authMethodSelected:(id)sender;
- (IBAction)showAddSheet:(id)sender;
- (IBAction)editType:(id)sender;
- (void) showMySQLSheet;
- (void)reloadAuthMethods;


@end