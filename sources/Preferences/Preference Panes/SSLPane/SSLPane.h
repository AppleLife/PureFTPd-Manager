/* SSLPane */

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import <Foundation/Foundation.h>

#define TLS1 NSLocalizedString(@"Support for SSL/TLS is disabled.", @"Support for SSL/TLS is disabled")
#define TLS2 NSLocalizedString(@"Clients can connect either the traditional way or through an SSL/TLS layer.", @"SSL Mixed mode comment")
#define TLS3 NSLocalizedString(@"Cleartext sessions are refused and only SSL/TLS compatible clients are accepted.", @"SSL/TLS clients only")



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
