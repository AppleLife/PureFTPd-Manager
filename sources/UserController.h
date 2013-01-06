/* UserController */

#import <Cocoa/Cocoa.h>
#import "WBTimeControl.h"
#import "VirtualUser.h"
#import "PureDBUserManager.h"
#import "MySQLUserManager.h"
#import "NSBrowserView.h"
#import "JMNavSplitView.h"

enum DBType {PureDB = 1, MySQL = 2};

@class PureDBUserManager, NSXTimeControl, PureController;

@interface UserController : NSObject
{
    IBOutlet NSTextField *allowClientField;
    IBOutlet NSButton *allowClientRemoveButton;
    IBOutlet NSTableView *allowClientTable;
    IBOutlet NSTextView *bannerTextView;
    IBOutlet NSButton *chooseUserDirButton;
    IBOutlet NSButton *chrootSwitch;
    IBOutlet NSTextField *denyClientField;
    IBOutlet NSButton *denyClientRemoveButton;
    IBOutlet NSTableView *denyClientTable;
    IBOutlet NSTextField *downBwField;
    IBOutlet NSTextField *downRatioField;
    IBOutlet NSTextField *fileQuotaField;
    IBOutlet NSTextField *fullNameField;
    IBOutlet NSPopUpButton *groupPopUp;
    IBOutlet NSTextField *homeDirField;
    IBOutlet NSTextField *loginField;
    IBOutlet NSTextField *maxSessionsField;
    IBOutlet NSSecureTextField *passwordField;
    IBOutlet NSButton *removeBannerBtn;
    IBOutlet NSButton *resetPwdButton;
    IBOutlet NSTextField *sizeQuotaField;
    IBOutlet NSTextField *timeAccessField;
    IBOutlet NSButton *timeAccessSwitch;
    IBOutlet WBTimeControl *timeBeginControl;
    IBOutlet WBTimeControl *timeEndControl;
    IBOutlet NSTextField *upBwField;
    IBOutlet NSTextField *upRatioField;
    IBOutlet NSPopUpButton *userDBPopUp;
    IBOutlet NSPopUpButton *userPopUp;
    IBOutlet NSTableView *userTable;
    IBOutlet NSTabView *userTabView;
    IBOutlet NSSearchField *userSearchField;
    
    PureController *pureController;
    int currentUserManager;
    PureDBUserManager *pureUM;
    MySQLUserManager *mySQLUM;
    
    NSMutableArray *authMethods;
    NSMenu *authMenu;
    NSMutableDictionary *myUsersDictionary;
    NSArray *sortedArray;
    VirtualUser *currentUser;
    VirtualUser *revertedUser;
    
    NSBrowserView *fileBrowserView;
    NSBrowser *fileBrowser;
    JMNavSplitView *splitview;
    NSControl *sidebar;
    IBOutlet NSView *navView;
    IBOutlet NSTableView *vfolderTable;
    IBOutlet NSButton *vfolderAccessButton;
    IBOutlet NSButton *vfolderRemoveButton;
    IBOutlet NSPanel *vfolderResultPanel;
    IBOutlet NSTextView *vfolderResultTextView;
    NSMutableArray *userVFolderList;
    IBOutlet NSPopUpButton *accessPopUp;
    
	IBOutlet NSButton *activationSwitch;
	
    SInt32 MacVersion;
    
}

+ (id)getInstance;

- (void)setUserAndGroupPopup;
/* Check if the mandatory infos (account,  password, homedir, uid and gid) have been set */
- (BOOL)isDuplicated:(VirtualUser *)user;
- (void)getUserInfoFor:(VirtualUser*) user;
- (VirtualUser *)currentUser;
- (void)disableUserFields;
- (void)enableUserFields;
- (void)clearFields;

- (NSTableView *)userTable;

- (void)createUser;
- (void)deleteUser;
- (void)saveUser;
- (void)saveAlert;
- (void)synchronizeUserDB;
- (void)selectRowWithName:(NSString *)name;

- (void)generateAuthentificationPopUp;

-(void)changeUserDB:(id)sender;

- (IBAction)chrootAccess:(id)sender;
- (IBAction)chooseDir:(id)sender;
- (IBAction)removeBanner:(id)sender;
- (IBAction)resetPassword:(id)sender;
- (IBAction)setGroupID:(id)sender;
- (IBAction)setTimeValue:(id)sender;
- (IBAction)setUserID:(id)sender;
- (IBAction)toggleTimeRestrictions:(id)sender;
- (IBAction)userIPFilter:(id)sender;

- (IBAction)reloadBrowserData:(id)sender;
- (IBAction)adjustAccessToFolder:(id)sender;
- (IBAction)setAccessToFolder:(id)sender;
- (void)getAccessToFolder:(NSString *)path;
- (IBAction)removeVFolder:(id)sender;
- (void)refreshVFolderList;
- (void)appendString:(NSString *)string toText:(NSTextView *)tv;
- (void)setBrowserPath:(NSString *)aPath;

- (IBAction)toggleAccountStatus:(id)sender; 


@end
