/* PermissionPane */

#import <Cocoa/Cocoa.h>
#import <PreferencePanes/NSPreferencePane.h>
#import <Foundation/Foundation.h>




@interface PermissionPane : NSPreferencePane
{
    IBOutlet NSButton *checkVFolderButton;
    IBOutlet NSButton *consoleButton;
    IBOutlet NSPopUpButton *groupFilePopUp;
    IBOutlet NSPopUpButton *groupFolderPopUp;
    IBOutlet NSPopUpButton *otherFilePopUp;
    IBOutlet NSPopUpButton *otherFolderPopUp;
    IBOutlet NSTextField *umaskFileField;
    IBOutlet NSTextField *umaskFolderField;
    IBOutlet NSPopUpButton *userFilePopUp;
    IBOutlet NSPopUpButton *userFolderPopUp;
    
    BOOL modified;
}

-(void)loadPreferences;
-(void)savePreferences;

- (IBAction)didModify:(id)sender;
// calculate mask
- (IBAction)fileMaskChanged:(id)sender;
- (IBAction)folderMaskChanged:(id)sender;

//set defafuls mask value (133 for files, 022 for folders)
- (IBAction)setDefaultMask:(id)sender;

// set file and folders permissions popup based on umask
-(void)setFileRepresentationForMask:(NSString *)umask;
-(void)setFolderRepresentationForMask:(NSString *)umask;


@end
