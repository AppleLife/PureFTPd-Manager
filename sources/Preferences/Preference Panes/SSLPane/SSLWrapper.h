/* SSLWrapper */

#import <Cocoa/Cocoa.h>

@interface SSLWrapper : NSObject
{
    IBOutlet NSPopUpButton *bitsPopup;
    IBOutlet NSFormCell *country;
    IBOutlet NSFormCell *day;
    IBOutlet NSFormCell *email;
    IBOutlet NSButton *generateBtn;
    IBOutlet NSFormCell *locality;
    IBOutlet NSFormCell *name;
    IBOutlet NSFormCell *organization;
    IBOutlet NSFormCell *state;
    IBOutlet NSFormCell *unit;
    IBOutlet NSProgressIndicator *wheel;
    
    IBOutlet NSWindow *aWindow;
}

- (void)createCert;

- (IBAction)generateCert:(id)sender;
- (IBAction)closeWindow:(id)sender;
@end
