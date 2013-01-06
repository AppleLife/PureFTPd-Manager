/*
    PureFTPd Manager
    Copyright (C) 2003 Jean-Matthieu Schaffhauser <jean-matthieu@users.sourceforge.net>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import <Cocoa/Cocoa.h>
#include <sys/types.h>
#include <pwd.h>
#include <grp.h>
#import "defines.h"

#import "StatusController.h"
#import "LogManager.h"
#import "UserController.h"
#import "VHostManager.h"

#import "PureFTPD.h"
#import "MVPreferencesController.h"
#import "NSXAppKit.h"



@class StatusController,PureFTPD, VHostManager;

@interface PureController : NSObject
{

    NSToolbar *toolbar;
    NSMutableDictionary *toolbarItems;
    
    IBOutlet NSButton *deleteButton;

    IBOutlet NSWindow *window;
    IBOutlet NSPanel *donationPanel;
    BOOL showSplash;
    IBOutlet NSTabView *mainTabView;
    
    IBOutlet NSButton *chooseVHostDirButton;
    IBOutlet NSTextField *vhostDirField;
    IBOutlet NSTextField *vhostIPField;
    IBOutlet NSTextField *vhostNameField;
    IBOutlet NSTableView *vhostTable;
    IBOutlet NSPopUpButton *vhostNICPopUp;
    
    // upgarde stuff
    IBOutlet NSWindow *updatePanel;
    IBOutlet NSTextField *versionNumber;
    IBOutlet NSTextView *changeLog;
    
    // About
    IBOutlet NSTextView * creditsTextView;
    
	IBOutlet NSPopUpButton *donationPopUp;
    
 
    
    NSFileManager *fm;    
    
    StatusController *statusController;
    LogManager *logManager;
    UserController *userController;
    VHostManager *vhostManager;
    PureFTPD *pureFTPD;
    NSMenu *dockMenu;
    
    BOOL selectNow; // for the main tabView
    BOOL prefWinWasVisible;
    BOOL bannerModified;
    MVPreferencesController*  	preferencesController;
	
    // Active user
    NSString *activeUser;
}

- (IBAction)splashAction:(id)sender;

- (void)makeTranslucent;
-(void) loadPreferences;
-(IBAction) launchAssistant:(id)sender ;
-(IBAction) pdfHelp:(id)sender ;
-(IBAction)gotoPayPal:(id)sender;
-(IBAction) checkForNewVersion:(id)sender;
-(void) newVersionThread:(id)sender;
-(IBAction) upgradeNow:(id)sender;

-(void)setupToolbar;
-(void)showTab:(id)sender;
-(void)selectAddAction:(id)sender;
-(void)selectDeleteAction:(id)sender;
-(void)selectSaveAction:(id)sender;
-(void)refreshContents:(id)sender;

+(id) getInstance;
-(void) setDockMenu;
- (MVPreferencesController *)preferencesController;

/* choose buttons actions */
- (IBAction)chooseDir:(id)sender; 
- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo;

/* status actions */
-(void) startServer:(id)sender;
-(void) stopServer:(id)sender;

/* vhosts info */
-(void) getHostInfoFor:(NSMutableDictionary *)infoDict;
-(void) disableHostFields;
-(void)enableHostFields;
-(void) clearHostFields;
-(NSTableView *)vhostTable;
-(NSTextField *)vhostDirField;
-(NSTextField *)vhostIPField;
-(NSTextField *)vhostNameField;
-(NSPopUpButton *)vhostNICPopUp;

/* TextFields delegates */
//- (void)controlTextDidChange:(NSNotification *)aNotification;

- (void) setSelectNow:(BOOL)opt;
- (BOOL) selectNow;


- (NSTabView *)mainTabView;

- (NSString *)activeUser;

- (void)registerHelp;

@end
