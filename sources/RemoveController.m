/*
 PureFTPd Manager
 Copyright (C) 2003-2004 Jean-Matthieu Schaffhauser <jean-matthieu@users.sourceforge.net>
 
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

#import "RemoveController.h"
RemoveController * theRC = nil;
@implementation RemoveController

- (void)awakeFromNib
{
    quitNow = NO;
    [infoField setStringValue:@""];
    [progressWheel setDisplayedWhenStopped:NO];
    theRC = self;
}

+(id) getInstance
{
    // TODO: Mutex Begin
    if (theRC == nil) {
        theRC = [[RemoveController alloc] init];
    }
    // TODO: Mutex End
    return theRC;
}

- (IBAction)showUninstaller:(id)sender
{
    [window makeKeyAndOrderFront:nil];
}


- (IBAction)removeManager:(id)sender
{
    if (quitNow)
        [NSApp terminate:nil];
    
	
    // Restore original FTP server
    SInt32 MacVersion;
    Gestalt(gestaltSystemVersion, &MacVersion);
	if (MacVersion >= 0x1040)
	{
		NSString *ftpPath = @"/System/Library/LaunchDaemons/ftp.plist";
		NSString *ftpTiger = [[NSBundle mainBundle] pathForResource:@"ftptiger" ofType:nil];
		//[[NSFileManager defaultManager] copyPath:ftpTiger toPath:ftpPath handler:nil];
		NSString *originalLaunchd = [NSString stringWithContentsOfFile:ftpTiger];
		[originalLaunchd writeToFile:ftpPath atomically:YES];
	} else {
		NSString *originalXinetd = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ftposx" ofType:nil]];
		[originalXinetd writeToFile:@"/etc/xinetd.d/ftp" atomically:YES];
    }
	
	[self appendString:NSLocalizedString(@"Mac OS X default FTP server has been restored\n",@"Mac OS X default ftp server has been restored") toText:textView];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    [continueButton setEnabled:NO];
    [infoField setStringValue:NSLocalizedString(@"Uninstalling PureFTPd Manager...", @"Uninstalling PureFTPd Manager...")];
    [tabView selectTabViewItemWithIdentifier:@"textView"];
    [progressWheel startAnimation:nil];
    
    NSArray *removeThem = [NSArray arrayWithArray:[self prepareUninstall]];
    NSString *path = nil;
    NSEnumerator *fileEnum = [removeThem objectEnumerator];
    
    while(path = [fileEnum nextObject]){
        // append info to textView
        [fm removeFileAtPath:path handler:nil];
        [self appendString:[NSString stringWithFormat:NSLocalizedString(@"File: %@ removed.",@"File:/path/to/file removed.") , path] toText:textView];
    }
    
    // Files were removed, now we restore factory setting
    // Remove PUREFTPD from /etc/hostconfig
    NSString *hostConfig = [NSString stringWithContentsOfFile:@"/etc/hostconfig"];
    NSString *newConfig = nil;
    NSRange pRange = [hostConfig rangeOfString:@"PUREFTPD"];
    
    if (!(pRange.length==0)) // Can't find entry in /etc/hostconfig; we add it
    {
        NSRange lineRange = [hostConfig lineRangeForRange:pRange];
        NSString *before = [NSString stringWithString:[hostConfig substringToIndex:lineRange.location]];
        NSString *after = [NSString stringWithString:[hostConfig substringFromIndex:NSMaxRange(lineRange)]];
        
        newConfig = [NSString stringWithFormat:@"%@\r\n%@", before, after];
    }
    
    [newConfig writeToFile:@"/etc/hostconfig" atomically:YES];
    [self appendString:NSLocalizedString(@"\nPureFTPd informations removed from your host configuration file.",@"PureFTPd informations removed from your host configuration file.") toText:textView];
    
    
    [continueButton setEnabled:YES];
    [progressWheel stopAnimation:nil];
    [infoField setStringValue:NSLocalizedString(@"Uninstall process completed", @"PureFTPd Manager has been removed from your system.")];
    [self appendString:NSLocalizedString(@"\nPureFTPd Manager has been removed from your system.",@"PureFTPd Manager has been removed from your system.") toText:textView];
    [continueButton setTitle:NSLocalizedString(@"Close", @"Close uninstaller")];
    quitNow = YES;
        
}

- (NSArray *)prepareUninstall
{
    NSMutableArray *filesToRemove = [[[NSMutableArray alloc] init] autorelease];
  
    [filesToRemove addObject:@"/private/etc/pam.d/pure-ftpd"];
    [filesToRemove addObject:@"/private/etc/pure-ftpd/pureftpd-dir-aliases"];
    [filesToRemove addObject:@"/private/etc/pure-ftpd/pureftpd-mysql.conf"];
    [filesToRemove addObject:@"/Library/StartupItems/PureFTPD"];
    [filesToRemove addObject:@"/usr/local/bin/PureFTPOSX"];
    
    if (![keepPreferences state] && ![keepPureDB state] && ![keepSSL state]){
        [filesToRemove addObject:@"/private/etc/pure-ftpd"];
    } else {
        if ([keepPreferences state] == NSOffState){
            [filesToRemove addObject:@"/private/etc/pure-ftpd/pure-ftpd.plist"];
        }
        if ([keepPureDB state] == NSOffState){
            [filesToRemove addObject:@"/private/etc/pure-ftpd/pureftpd.passwd"];
            [filesToRemove addObject:@"/private/etc/pure-ftpd/pureftpd.pdb"];
        }
        if ([keepSSL state] == NSOffState){
            [filesToRemove addObject:@"/private/etc/pure-ftpd/ssl"];
        }
    }
    
    [filesToRemove addObject:@"/usr/local/bin/pure-pw"];
    [filesToRemove addObject:@"/usr/local/bin/pure-pwconvert"];
    [filesToRemove addObject:@"/usr/local/bin/pure-statsdecode"];
    [filesToRemove addObject:@"/usr/local/man/man8/pure-authd.8"];
    [filesToRemove addObject:@"/usr/local/man/man8/pure-ftpd.8"];
    [filesToRemove addObject:@"/usr/local/man/man8/pure-ftpwho.8"];
    [filesToRemove addObject:@"/usr/local/man/man8/pure-mrtginfo.8"];
    [filesToRemove addObject:@"/usr/local/man/man8/pure-pw.8"];
    [filesToRemove addObject:@"/usr/local/man/man8/pure-pwconvert.8"];
    [filesToRemove addObject:@"/usr/local/man/man8/pure-quotacheck.8"];
    [filesToRemove addObject:@"/usr/local/man/man8/pure-statsdecode.8"];
    [filesToRemove addObject:@"/usr/local/man/man8/pure-uploadscript.8"];
    [filesToRemove addObject:@"/usr/local/sbin/pure-authd"];
    [filesToRemove addObject:@"/usr/local/sbin/pure-ftpd"];
    [filesToRemove addObject:@"/usr/local/sbin/pure-ftpwho"];
    [filesToRemove addObject:@"/usr/local/sbin/pure-mrtginfo"];
    [filesToRemove addObject:@"/usr/local/sbin/pure-quotacheck"];
    [filesToRemove addObject:@"/usr/local/sbin/pure-uploadscript"];
   
    [filesToRemove addObject:@"/Library/Receipts/PureFTPd Manager.pkg"];
    [filesToRemove addObject:@"/Library/Receipts/pureftpd-jaguar.pkg"];
    [filesToRemove addObject:@"/Library/Receipts/pureftpd-panther.pkg"];
    
    [filesToRemove addObject:@"/Applications/PureFTPd Manager.app"];
    
    return filesToRemove;
}


#define END_RANGE NSMakeRange([[tv string]length],0)
- (void)appendString:(NSString *)string toText:(NSTextView *)tv
{
    [tv replaceCharactersInRange:END_RANGE withString:string];
    [tv replaceCharactersInRange:END_RANGE withString:@"\n"];
    
    if ([[tv window] isVisible]) {
        [tv scrollRangeToVisible:END_RANGE];
    }
}


@end
