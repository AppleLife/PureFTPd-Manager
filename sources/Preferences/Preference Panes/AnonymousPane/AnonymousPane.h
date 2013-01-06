

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import <Foundation/Foundation.h>


@interface AnonymousPane : NSPreferencePane
{
    IBOutlet NSButton *anonCreateDirSwitch;
    IBOutlet NSTextField *anonDownBWField;
    IBOutlet NSTextField *anonDownRatioField;
    IBOutlet NSButton *anonNoAccessSwitch;
    IBOutlet NSButton *anonNoDownSwitch;
    IBOutlet NSButton *anonNoUpSwitch;
    IBOutlet NSTextField *anonUpBWField;
    IBOutlet NSTextField *anonUpRatioField;
    IBOutlet NSTextField *maxLoadField;
    IBOutlet NSButton *removeBannerBtn;
    IBOutlet NSTextView *bannerTxtView;
	IBOutlet NSTextField *homeDirField;
    
    NSString *homeDirectory;
	BOOL homeDirSet;
    NSFileManager *fm;
    NSMutableDictionary *pureFTPPreferences;
    BOOL modified;
    
    IBOutlet NSBrowser *fileBrowser;
    IBOutlet NSTableView *vfolderTable;
    IBOutlet NSButton *vfolderRemoveButton;
    NSMutableArray *userVFolderList;
   
}

- (void)loadPreferences;
- (void)savePreferences;
- (IBAction)didModify:(id)sender;
- (void) loadBanner;
- (void) saveBanner;
- (IBAction)removeBanner:(id)sender;

- (IBAction)reloadBrowserData:(id)sender;
- (IBAction)removeVFolder:(id)sender;
- (void)refreshVFolderList;

- (IBAction)chooseDir:(id)sender;

@end