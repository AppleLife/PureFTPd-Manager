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


#include <sys/types.h>
#include <pwd.h>
#include <grp.h>
#import "defines.h"
#import "wizardController.h"

@implementation wizardController

-(void) awakeFromNib
{
    [prevTabButton setEnabled:NO];
    
    [anonGroupPopUp removeAllItems];
    NSString *groupname;
    struct group *gInfo;
    while((gInfo=getgrent()) != NULL)
    {
        groupname = [NSString stringWithFormat:@"%s", gInfo->gr_name];
        [anonGroupPopUp addItemWithTitle:groupname];
        [[anonGroupPopUp lastItem] setTag: gInfo->gr_gid];
    }
    
    [anonGroupPopUp selectItemWithTitle:@"unknown"];
}

- (BOOL)windowShouldClose:(id)sender{
    NSBeginAlertSheet(@"Do you really want to quit ?", @"Quit", @"Cancel",  nil,
                                        [NSApp mainWindow], self, @selector(closeWizard:returnCode:contextInfo:), 
                                        NULL, NULL, @"Pure-FTPd Wizard is not complete. Are you sure you want to quit this Application ?", nil);
    //[NSApp terminate:self];
    return NO;
}


- (void)closeWizard: (NSWindow *)sheet
        returnCode: (int)returnCode
        contextInfo: (void *)contextInfo
{
    if (returnCode == NSAlertDefaultReturn)
    {
        [NSApp terminate:self];
    }
    else 
        [NSApp stopModal];
}

- (void) addToStartup
{
    NSString *hostConfig = [NSString stringWithContentsOfFile:@"/etc/hostconfig"];
    NSString *newConfig;
    NSRange pRange = [hostConfig rangeOfString:@"PUREFTPD"];
    
    if (pRange.length==0) // Can't find entry in /etc/hostconfig; we add it
        newConfig = [NSString stringWithString:[hostConfig stringByAppendingString:@"\nPUREFTPD=-YES-\n"]];
    else 
    {
        NSRange lineRange = [hostConfig lineRangeForRange:pRange];
        NSString *before = [NSString stringWithString:[hostConfig substringToIndex:lineRange.location]];
        NSString *after = [NSString stringWithString:[hostConfig substringFromIndex:NSMaxRange(lineRange)]];
        
        NSString *pStatus=@"PUREFTPD=-YES-\n";
        
        newConfig = [NSString stringWithFormat:@"%@%@%@", before, pStatus, after];
    }
    
    [newConfig writeToFile:@"/etc/hostconfig" atomically:YES];
}

-(NSMutableArray *) getSysUsers
{
    struct passwd *userInfo;
    NSMutableArray *userArray = [NSMutableArray array];
   
    while((userInfo=getpwent()) != NULL)
    {
        NSMutableDictionary *user = [NSMutableDictionary dictionary];
        [user setObject:[NSString stringWithFormat:@"%s", userInfo->pw_name] forKey:@"Username"];
        [user setObject:[NSNumber numberWithInt:userInfo->pw_uid] forKey:@"UID"];
        [userArray addObject:user];
    }
    //NSLog (@"%@", [userArray description]);
    return userArray;
}

-(NSMutableArray *) getSysGroups
{
    struct group *groupInfo;
    NSMutableArray *groupArray = [NSMutableArray array];

     while((groupInfo=getgrent()) != NULL)
    {
        NSMutableDictionary *group = [NSMutableDictionary dictionary];
        [group setObject:[NSString stringWithFormat:@"%s", groupInfo->gr_name] forKey:@"Group"];
        [group setObject:[NSNumber numberWithInt:groupInfo->gr_gid] forKey:@"GID"];
        [groupArray addObject:group];
        
    }
    
    //NSLog (@"%@", [groupArray description]);
    return groupArray;
}



-(BOOL) uniqUID:(int) aUID
{
    NSMutableArray *myUsers = [NSMutableArray arrayWithArray:[self getSysUsers]];
    NSMutableDictionary *user;
    NSEnumerator *enumerate = [myUsers objectEnumerator];
    
    while (user = [enumerate nextObject])
    {
        NSNumber *uid = [NSNumber numberWithInt:[[user objectForKey:@"UID"] intValue]];
        if ( aUID == [uid intValue])
            return NO;
    }
    
    return YES;
}

-(BOOL) uniqGID:(int) aGID
{
    NSMutableArray *myGroups = [NSMutableArray arrayWithArray:[self getSysGroups]];
    NSMutableDictionary *group;
    NSEnumerator *enumerate = [myGroups objectEnumerator];
    
    while (group = [enumerate nextObject])
    {
        NSNumber *gid = [NSNumber numberWithInt:[[group objectForKey:@"GID"] intValue]];
        if ( aGID == [gid intValue])
            return NO;
    }
    
    return YES;
}

- (IBAction)checkGID:(id)sender
{
    if(![self uniqGID:[vuserGIDField intValue]])
         NSRunInformationalAlertPanel(@"The chosen GID is already taken", @"Please try another one.",@"OK", nil, nil);
    
}

- (IBAction)checkUID:(id)sender
{
    NSTabViewItem *current = [tabView selectedTabViewItem];
    BOOL result = NO;
    if ([[current identifier] hasSuffix:@"anonymous"])
    {
        result = [self uniqUID:[anonUIDField intValue]];
    }
    
    else if ([[current identifier] hasSuffix:@"vusers"])
    {
        result = [self uniqUID:[vuserUIDField intValue]];
    }
    
    if(!result)
        NSRunInformationalAlertPanel(@"The chosen UID is already taken", @"Please try another one.",@"OK", nil, nil);
}

- (IBAction)chooseDir:(id)sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:NO];
    [oPanel setResolvesAliases:NO];
    
    [oPanel beginSheetForDirectory:NSHomeDirectory() file:nil types:nil 
                       modalForWindow:[NSApp mainWindow]
                       modalDelegate: self
                       didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo: (void *)[sender tag]];
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
    [NSApp stopModal];
    if (returnCode == NSOKButton && ((int)contextInfo==100)){
        [anonHomeField setStringValue: [[sheet filenames] objectAtIndex:0]];
    }
    else if (returnCode == NSOKButton && ((int)contextInfo==200)){
        [vuserBaseDirField setStringValue: [[sheet filenames] objectAtIndex:0]];
    }
    else if (returnCode == NSOKButton && ((int)contextInfo==300))
        [vhostBaseDirField setStringValue: [[sheet filenames] objectAtIndex:0]];
}

-(void) generateResume
{
    [finalTextView setString:@""];
        
    NSString *resume = [NSString stringWithString:@"Take a moment to review your Pure-FTPd settings"];
    resume = [resume stringByAppendingString:@"\n\n ð Anonymous Access:\n"];
    if ([anonSkipSwitch state])
        resume = [resume stringByAppendingString:@"\t Skipping Anonymous access setup ..."];
        
    else
    {
        resume = [resume stringByAppendingFormat:@"\tUsername:  ftp\n\tUID:  %@\n\tHome:  %@\n\tMember of:  %@", 
                                [anonUIDField stringValue], [anonHomeField stringValue], [anonGroupPopUp title] ];
    }
    
    
    
    resume = [resume stringByAppendingString:@"\n\n ð Virtual Users:\n"];
    resume = [resume stringByAppendingString:@" - Virtual users should be affiliated to the following system user : \n"];
    resume = [resume stringByAppendingFormat:@"\tUsername:  %@\n\tUID:  %@\n", 
                                [vuserLoginField stringValue], [vuserUIDField stringValue]];
    resume = [resume stringByAppendingString:@" - Their system group should be set to\n"];
    resume = [resume stringByAppendingFormat:@"\tGroup:  %@\n\tGID:  %@\n", 
                                [vuserGroupField stringValue], [vuserGIDField stringValue]];
    resume = [resume stringByAppendingFormat:@" - Default base directory for virtual users:\n\t %@", [vuserBaseDirField stringValue]];
    
    
    
    resume = [resume stringByAppendingString:@"\n\n ð Virtual Hosts:\n"];
    resume = [resume stringByAppendingFormat:@" - Default base directory for virtual hosts:\n\t %@", [vhostBaseDirField stringValue]];
    
    [finalTextView setString:resume];
}

- (IBAction)goClicked:(id)sender
{
    NSString *shellScript = [NSString stringWithString:@"#!/bin/sh\n"];
    NSString *anonScript = [NSString stringWithString:@"# Anonymous Account:\n"];
    NSString *vusersScript = [NSString stringWithString:@"\n# Virtual Users system account\n"];
    NSString *mkdirScript = [NSString stringWithString:@"\n# Creating Folders\n"];
    
  
    if ([anonSkipSwitch state])
    {
        anonScript = [anonScript stringByAppendingString:@"# \t Skipping Anonymous access setup ..."];
        shellScript = [shellScript stringByAppendingString:anonScript];
    }
    else
    {
        anonScript = [anonScript stringByAppendingFormat:@"niutil -create / /users/ftp \n niutil -createprop / /users/ftp expire 0 \n niutil -createprop / /users/ftp realname \"Anonymous FTP user\" \n niutil -createprop / /users/ftp name ftp \n niutil -createprop / /users/ftp passwd '*' \n niutil -createprop / /users/ftp change 0 \n niutil -createprop / /users/ftp home %@ \n niutil -createprop / /users/ftp uid %d \n niutil -createprop / /users/ftp gid %d \n niutil -createprop / /users/ftp shell /dev/null \n\n" , 
                            [anonHomeField stringValue], [anonUIDField intValue], [[anonGroupPopUp selectedItem] tag] ];
        anonScript = [anonScript stringByAppendingFormat:@"mkdir -p %@\n chmod 755 %@ \n chown root:wheel %@\n chmod 555 %@\n chown ftp:%@ %@\n mkdir %@\n chmod 755 %@\n chown ftp:%@ %@", 
                                                        [anonHomeField stringValue], 
                                                        [[anonHomeField stringValue] stringByDeletingLastPathComponent],
                                                        [[anonHomeField stringValue] stringByDeletingLastPathComponent],
                                                        [anonHomeField stringValue],
                                                        [anonGroupPopUp titleOfSelectedItem],
                                                        [anonHomeField stringValue],
                                                        [[anonHomeField stringValue] stringByAppendingPathComponent:@"incoming"],
                                                        [[anonHomeField stringValue] stringByAppendingPathComponent:@"incoming"],
                                                        [anonGroupPopUp titleOfSelectedItem],
                                                        [[anonHomeField stringValue] stringByAppendingPathComponent:@"incoming"]];
        shellScript = [shellScript stringByAppendingString:anonScript];
    }
    
    NSString *userRef = [NSString stringWithFormat:@"/users/%@", [vuserLoginField stringValue]];
    vusersScript = [vusersScript stringByAppendingFormat:@"niutil -create / %@\n niutil -createprop / %@ expire 0 \n niutil -createprop / %@ realname \"Virtual users account\" \n niutil -createprop / %@ name %@ \n niutil -createprop / %@ passwd '*' \n niutil -createprop / %@ change 0 \n niutil -createprop / %@ home /dev/null \n niutil -createprop / %@ uid %d \n niutil -createprop / %@ gid %d \n niutil -createprop / %@ shell /etc/pure-ftpd\n", userRef, userRef, userRef, userRef, [vuserLoginField stringValue], userRef, userRef, userRef, userRef, [vuserUIDField intValue], userRef, [vuserGIDField intValue], userRef];
    
    NSString *groupRef = [NSString stringWithFormat:@"/groups/%@", [vuserGroupField stringValue]];
    vusersScript = [vusersScript stringByAppendingFormat:@"niutil -create / %@ \n niutil -createprop / %@ passwd '*'\n niutil -createprop / %@ gid %d\n niutil -createprop / %@ users %@", groupRef, groupRef, groupRef, [vuserGIDField intValue], groupRef, [vuserLoginField stringValue]];
        
    shellScript = [shellScript stringByAppendingString:vusersScript];
    
    mkdirScript = [mkdirScript stringByAppendingFormat:@"mkdir -p %@\n chown %@:%@ %@\n chmod 555 %@\n mkdir -p %@", [vuserBaseDirField stringValue], [vuserLoginField stringValue], [vuserGroupField stringValue], [vuserBaseDirField stringValue], [vuserBaseDirField stringValue], [vhostBaseDirField stringValue]];
    
            
    shellScript = [shellScript stringByAppendingString:mkdirScript];
    if ([startupSwitch state])
        shellScript = [shellScript stringByAppendingString:@"\necho PUREFTPD=-YES- >> /etc/hostconfig"];
    else
        shellScript = [shellScript stringByAppendingString:@"\necho PUREFTPD=-NO- >> /etc/hostconfig"];
        
    
    NSLog(@"%@", shellScript);

    [shellScript writeToFile:@"/tmp/Pure-FTPd.sh" atomically:YES];
    NSTask *setup = [[NSTask alloc] init];
    [setup setArguments:[NSMutableArray arrayWithObjects:@"/tmp/Pure-FTPd.sh", nil]];
    [setup setLaunchPath:@"/bin/sh"];
    [setup launch];
    [setup release];
    
    NSMutableDictionary *prefs = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/etc/pure-ftpd/pure-ftpd.plist"];
    [prefs setObject:[vuserBaseDirField stringValue] forKey:PureFTPUserBaseDir];
    [prefs setObject:[vhostBaseDirField stringValue] forKey:PureFTPVHostBaseDir];
    NSNumber *atStartup = [[NSNumber alloc] initWithInt:[startupSwitch state]];
    [prefs setObject:atStartup forKey:PureFTPAtStartup];
    [prefs writeToFile:@"/etc/pure-ftpd/pure-ftpd.plist" atomically:YES];
    [atStartup release];
    
    //NSUserDefaults *userdef = [NSUserDefaults standardUserDefaults];
    //BOOL done = YES;
    //[userdef setBool:done forKey:@"wizardCompleted"];
    //[userdef synchronize];
    
    // Writes to /Library/Preferences/org.pureftpd.macosx.plist
    
    CFStringRef appID = CFSTR("org.pureftpd.macosx");
    CFStringRef key = CFSTR("wizardCompleted");
    CFStringRef errorString;
    CFBooleanRef done = kCFBooleanTrue; 
    CFDataRef   xmlData;
    CFPropertyListRef plist;
   
    xmlData = CFPropertyListCreateXMLData( kCFAllocatorDefault, done );

    plist = CFPropertyListCreateFromXMLData(kCFAllocatorDefault,
                 xmlData, kCFPropertyListImmutable, &errorString);
                 
    CFPreferencesSetValue(key, done, appID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
    CFPreferencesSynchronize(appID, kCFPreferencesAnyUser, kCFPreferencesCurrentHost);
    
    //CFRelease(xmlData);
    //CFRelease(errorString);
    //CFRelease(appID);
    //CFRelease(key);
    
    // Launch the manager & quit
    NSString *bundleParent = [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent];
    
    NSTask *manager = [[NSTask alloc] init];
    [manager setLaunchPath:[bundleParent stringByAppendingPathComponent:@"PureFTPd-Manager.app/Contents/MacOS/PureFTPd-Manager"]];
    [manager launch];
    [manager release];
    
    [NSApp terminate:self];
    
}




- (BOOL)tabView:(NSTabView *)tabView shouldSelectTabViewItem:(NSTabViewItem *)tabViewItem
{
       
    if (![[tabViewItem identifier] hasSuffix:@"welcome"])
        [prevTabButton setEnabled:YES];
    else 
        [prevTabButton setEnabled:NO];
        
    if (![[tabViewItem identifier] hasSuffix:@"final"])
        [nextTabButton setEnabled:YES];
    else 
        [nextTabButton setEnabled:NO];
        
    if ([[tabViewItem identifier] hasSuffix:@"final"])
        [self generateResume];
    
    
    int index = [tabView indexOfTabViewItem:tabViewItem];
    int i =0;
    [radioMatrix deselectAllCells];
    for (i; i<=index; i++)
        [radioMatrix selectCellAtRow:i column:0]; //NSLog(@"%d\n", i);
    
    return YES;
}


@end
