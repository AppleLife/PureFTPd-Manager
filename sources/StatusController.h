/* StatusController */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "defines.h"

#import "PureFTPD.h"
#import "FTPUsage.h"



@interface StatusController : NSObject
{
    IBOutlet NSButton *autoUpdateSwitch;
    IBOutlet NSButton *closeAllSessionsBtn;
    IBOutlet NSButton *closeOneSessionBtn;
    IBOutlet NSButton *controlServerBtn;
    IBOutlet NSTextField *fileField;
    IBOutlet NSTextField *localHostField;
    IBOutlet NSTextField *localPortField;
    IBOutlet NSTextField *pidField;
    IBOutlet NSProgressIndicator *progress;
    IBOutlet NSTextField *resumeField;
    IBOutlet NSTextField *serverStatusField;
    IBOutlet NSTextField *sessionInfoField;
    IBOutlet WebView *statusWV;
    IBOutlet NSTextField *sizeField;
    IBOutlet NSTableColumn *tc_bandwidth;
    IBOutlet NSTextField *totalBWUsageField;
    IBOutlet NSTableView *userDetailTable;
    IBOutlet NSTabView *userTab;
    IBOutlet NSTableView *userTable;    
    PureFTPD *pureFTPD;
    FTPUsage *myUsage;
    NSMutableDictionary *statusDictionary;
    NSMutableArray *sortedArray;
    
    NSTimer *autoUpdateTimer;
}

+ (id)getInstance;


- (void)updateUserStatus;
- (void)updateServerStatus;
- (void)refreshStatus:(NSNotification *)notification;
- (void) startServer:(id)sender;
- (void) stopServer:(id)sender;

- (IBAction)closeAllSessions:(id)sender;
- (IBAction)closeSession:(id)sender;
- (IBAction)controlServer:(id)sender;
-(NSNumber *)formatSize:(NSNumber *)number forCell:(id)cell;

- (IBAction)toggleAutoUpdate:(id)sender;
@end
