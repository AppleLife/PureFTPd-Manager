/* DirAliasesPane */

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import <Foundation/Foundation.h>

@class PureController;

@interface DirAliasesPane : NSPreferencePane
{
    IBOutlet NSTableView *aliasesTable;
    IBOutlet NSTextField *folderField;
    IBOutlet NSTextField *nameField;
    IBOutlet NSButton *removeBtn;
    IBOutlet NSWindow *addWindow;
    
    NSMutableArray *dirAliases;
    BOOL modified;
}

- (void)parseAliases;
- (void)saveAliases;

- (IBAction)addAlias:(id)sender;
- (IBAction)addCancel:(id)sender;
- (IBAction)addOK:(id)sender;
- (IBAction)chooseDir:(id)sender;
- (IBAction)removeAlias:(id)sender;
@end
