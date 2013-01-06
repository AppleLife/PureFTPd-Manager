/* SSLPane */

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import <Foundation/Foundation.h>


@class PureController;

@interface SSLPane : NSPreferencePane
{
    IBOutlet NSButton *createBtn;
    IBOutlet NSButton *removeBtn;
    IBOutlet NSButton *viewBtn;
    IBOutlet NSTextField *sslField;
    IBOutlet NSTextView *certTextView;
    IBOutlet NSWindow *certWindow;
    IBOutlet NSWindow *newCertWindow;
    IBOutlet NSWindow *viewCertWindow;
    IBOutlet NSPopUpButton *tlsPopUp;
    
    NSFileManager *fm;
    NSMutableDictionary *pureFTPPreferences;
    BOOL modified;
}

-(void)loadPreferences;
-(void)savePreferences;
-(void)activateUI;
-(void) restrictSSLFileAttributes;

- (IBAction)didModify:(id)sender;
- (IBAction)importCert:(id)sender;
- (IBAction)removeCert:(id)sender;
- (IBAction)showTLS:(id)sender;
- (IBAction)startCert:(id)sender;
- (IBAction)viewCert:(id)sender;
- (IBAction)closeView:(id)sender;

@end
