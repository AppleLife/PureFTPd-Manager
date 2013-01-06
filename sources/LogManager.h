/* LogManager */

#import <Cocoa/Cocoa.h>
#import "defines.h"
#include <sys/types.h>
#include "unistd.h"

#import "MKLogfileReader.h"
#import "MVPreferencesController.h"
#import "UserStatsController.h"
#import "GraphController.h"



@interface LogManager : NSObject
{
    IBOutlet NSTabView *logTab;
    IBOutlet NSTableView *logTable;
    IBOutlet NSTableView *usersTable;
    IBOutlet NSTableView *ftpTable;
    IBOutlet NSButton *refreshButton;
    
    IBOutlet NSButton *clearButton; 
    IBOutlet NSTextView *serverLogTV;
    
    IBOutlet NSTextField *fileField;
    IBOutlet NSTextField *ipField;
    IBOutlet NSPopUpButton *graphMonthPop;
    IBOutlet NSPopUpButton *graphYearPop;
    
    IBOutlet NSProgressIndicator *progressWheel;
    IBOutlet NSTextField *progressField;
    
    IBOutlet NSSplitView *userSplitview;
    
    
    NSMutableArray *readerList;
    NSTimer *timer;
    int	cycle;
    int koctet;
    unsigned long   moctet;
    unsigned long   goctet;
    unsigned long   toctet;
    
    UserStatsController *myUserStats;
    NSMutableDictionary *usersDictionary;
    NSArray *sortedArray;
    BOOL reloadingTables;
}

+(id) getInstance;

// serverLogTV actions
- (void)start;
- (void)stop;

-(NSMutableDictionary *) usersDictionary;
-(NSArray *) sortedArray;
-(NSTableView *)usersTable;
-(NSTableView *)ftpTable;

- (void)clearProgressField:(NSNotification *)notification;
-(IBAction) refreshAction:(id)sender;
-(void) loggingAlert;
-(NSButton *)refreshButton;
- (void)createYearMenu;
- (void)createMonthMenuForYear:(id)sender;
- (void)refreshMenu;
-(void)refreshUserGraph:(id) sender;

-(void) reloadUserStats:(id)anObject;
-(void) reloadTables:(id)sender;
-(NSNumber *)formatSize:(NSNumber *)number;


- (IBAction)cancelThread:(id)sender;
- (IBAction)printServerLog:(id)sender;
- (IBAction)clearLog:(id)sender;
@end
