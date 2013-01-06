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
#import <CoreFoundation/CoreFoundation.h>

@interface wizardController : NSObject
{
    IBOutlet NSPopUpButton *anonGroupPopUp;
    IBOutlet NSTextField *anonHomeField;
    IBOutlet NSButton *anonSkipSwitch;
    IBOutlet NSTextField *anonUIDField;
    IBOutlet NSTextView *finalTextView;
    IBOutlet NSButton *nextTabButton;
    IBOutlet NSButton *prevTabButton;
    IBOutlet NSMatrix *radioMatrix;
    IBOutlet NSButton *startupSwitch;
    IBOutlet NSTabView *tabView;
    IBOutlet NSTextField *vhostBaseDirField;
    IBOutlet NSTextField *vuserBaseDirField;
    IBOutlet NSTextField *vuserGIDField;
    IBOutlet NSTextField *vuserGroupField;
    IBOutlet NSTextField *vuserLoginField;
    IBOutlet NSTextField *vuserUIDField;
    IBOutlet NSWindow *window;

    
}
- (void) addToStartup;
-(NSMutableArray *) getSysUsers;
-(NSMutableArray *) getSysGroups;
-(BOOL) uniqUID:(int) aUID;
-(BOOL) uniqGID:(int) aGID;;
- (IBAction)checkGID:(id)sender;
- (IBAction)checkUID:(id)sender;
- (IBAction)chooseDir:(id)sender;
- (IBAction)goClicked:(id)sender;
@end
