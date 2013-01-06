#import <Cocoa/Cocoa.h>
#import "PureFTPD.h"
extern NSString *MVPreferencesWindowNotification;

@class MVPreferencesMultipleIconView;
@class MVPreferencesGroupedIconView;

@interface MVPreferencesController : NSObject {
	IBOutlet NSWindow *window;
	IBOutlet NSView *loadingView;
	IBOutlet MVPreferencesMultipleIconView *multiView;
	IBOutlet MVPreferencesGroupedIconView *groupView;
	IBOutlet NSImageView *loadingImageView;
	IBOutlet NSTextField *loadingTextFeld;
	NSView *mainView;
	NSMutableArray *panes;
	NSMutableDictionary *loadedPanes, *paneInfo;
	NSString *currentPaneIdentifier, *pendingPane;
	BOOL closeWhenDoneWithSheet, closeWhenPaneIsReady;
        
	PureFTPD *mainsrv;
        
	NSUserDefaults *theDefaults;
	NSMutableDictionary *generalPrefsDict, *argumentsDict, *pureFTPPreferences; 
	id parent;
}
+ (MVPreferencesController *) sharedInstance;
+ (MVPreferencesController *) sharedInstanceWithParent:(id)parent;
- (void)setParent:(id)p;
- (NSWindow *) window;
- (void) showAll:(id) sender;
- (void) showPreferences:(id) sender;
- (void) selectPreferencePaneByIdentifier:(NSString *) identifier;

- (void)configureStartup;
- (void)setupXinetd;
- (void)setupStandAlone;

@end
