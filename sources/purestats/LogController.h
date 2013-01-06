/* LogController */

#import <Cocoa/Cocoa.h>
#import "HTMLConverter.h"
#import <WebKit/WebKit.h>

@interface LogController : NSObject
{
    IBOutlet NSPopUpButton *userPopUp;
    IBOutlet WebView *webview;
    
    HTMLConverter *htmlConverter;
}
- (IBAction)exportToHTML:(id)sender;
- (void)generateUserMenu;
- (void) showStatsForUser:(NSString *)aUser;
@end
