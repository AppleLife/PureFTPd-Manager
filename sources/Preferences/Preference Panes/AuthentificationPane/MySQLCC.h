/* MySQLCC */

#import <Cocoa/Cocoa.h>
#import <SMySQL_bundled/SMySQL_bundled.h>

@interface MySQLCC : NSObject
{
    IBOutlet NSButton *cryptSwitch;
	IBOutlet NSButton *defaultIDSwitch;
    IBOutlet NSPopUpButton *groupPopUp;
    IBOutlet NSButton *saveButton;
    IBOutlet NSTextField *sqlDatabase;
    IBOutlet NSTextField *sqlHost;
    IBOutlet NSSecureTextField *sqlPassword;
    IBOutlet NSTextField *sqlPort;
    IBOutlet NSButton *sqlTransactionSwitch;
    IBOutlet NSTextField *sqlUsername;
    IBOutlet NSPopUpButton *userPopUp;
    
    MCPConnection *mySQLConnection;
}
- (IBAction)cancel:(id)sender;
- (IBAction)save:(id)sender;
- (IBAction)useDefaultID:(id)sender;

- (void)setUserAndGroupPopup;
- (BOOL)prepareDatabase;
- (void)loadPreferences;
- (void)savePreferences;
- (void)saveMySQLConf;
- (void) enableSaveButton;
@end
