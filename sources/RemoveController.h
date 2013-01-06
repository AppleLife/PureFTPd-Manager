/* RemoveController */

#import <Cocoa/Cocoa.h>

@interface RemoveController : NSObject
{
    IBOutlet NSButton *continueButton;
    IBOutlet NSTextField *infoField;
    IBOutlet NSButton *keepPreferences;
    IBOutlet NSButton *keepPureDB;
    IBOutlet NSButton *keepSSL;
	IBOutlet NSButton *keepAnon;
    IBOutlet NSProgressIndicator *progressWheel;
    IBOutlet NSTabView *tabView;
    IBOutlet NSTextView *textView;
    IBOutlet NSWindow *window;
    
    BOOL quitNow;
}
+(id) getInstance;
- (IBAction)showUninstaller:(id)sender;
- (IBAction)removeManager:(id)sender;
- (void)appendString:(NSString *)string toText:(NSTextView *)tv;
- (NSArray *)prepareUninstall;

- (void)sighupCron;

@end
