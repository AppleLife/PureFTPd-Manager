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

#import "FTPLogPane.h"
#include <stdio.h>
#include <fcntl.h>
#include <kvm.h>
#include <sys/param.h>
#include <sys/sysctl.h>
#include <unistd.h>

@implementation FTPLogPane
- (id) initWithBundle:(NSBundle *) bundle {
    self = [super initWithBundle:bundle] ;
    
    return self ;
}

- (void) dealloc {
	[super dealloc];
}

- (void) mainViewDidLoad {
    pureFTPPreferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    modified=NO;
    [self loadPreferences];
}

- (void) willUnselect {
    if(modified)
        [self savePreferences];    
    [pureFTPPreferences release]; 
	[initialLogLocation release]; 
}

- (void) loadPreferences {
	
    [logSwitch setState:[[pureFTPPreferences objectForKey:PureFTPLogOnOff] intValue]];
    [updateSwitch setState:[[pureFTPPreferences objectForKey:PureFTPLogAutoUpdate] intValue]];
    [shareSwitch setState:[[pureFTPPreferences objectForKey:PureFTPLogNiceThread] intValue]];
    
    if ([logSwitch state] == 1)
    {
		[formatPopUp setEnabled:YES];
		[locationField setEnabled:YES];
		[browseButton setEnabled:YES];
        [updateSwitch setEnabled:YES];
        [shareSwitch setEnabled:YES];
		[convertSwitch setEnabled:YES];
    }
	
	if ([pureFTPPreferences objectForKey:PureFTPLogFormat] != nil){
		[formatPopUp selectItemWithTitle:[pureFTPPreferences objectForKey:PureFTPLogFormat]];
	}
	initialLogFormat = [formatPopUp indexOfSelectedItem];
	
	NSString *lastLogFile = nil;
    if ((lastLogFile=[pureFTPPreferences objectForKey:PureFTPLogLocation]) != nil)
    {
		[locationField setStringValue:lastLogFile];
    }
	 initialLogLocation = [[NSString alloc] initWithString:[locationField stringValue]];
	
	int convert = 0;
	convert = [[pureFTPPreferences objectForKey:PureFTPStatsConvertState] intValue];
	[convertSwitch setState:convert];
	[self toggleConvertion:convertSwitch];
		
    NSNumber *format = nil;
	NSNumber *details = nil;
    NSNumber *days = nil;
	NSString *ftime = nil;
	NSString *statsLocation = nil;
	
	if ((format=[pureFTPPreferences objectForKey:PureFTPStatsConvertFormat]) != nil)
    {
		[statFormatPopUp selectItemAtIndex:[format intValue]];
    }
	if ((details=[pureFTPPreferences objectForKey:PureFTPStatsConvertShowDetail]) != nil)
    {
		[detailOutputSwitch setState:[details intValue]];
    }
	if ((days=[pureFTPPreferences objectForKey:PureFTPStatsConvertDays]) != nil)
    {
		[daysPopUp selectItemAtIndex:[days intValue]];
    }
	if ((ftime=[pureFTPPreferences objectForKey:PureFTPStatsConvertTime]) != nil)
    {
		NSArray *_time = [ftime componentsSeparatedByString:@":"];
		[time setHour:[[_time objectAtIndex:0] intValue]];
		[time setMinute:[[_time objectAtIndex:1] intValue]];
		[time updateCells];
    }
	if ((statsLocation=[pureFTPPreferences objectForKey:PureFTPStatsConvertLocation]) != nil)
    {
		[saveToField setStringValue:statsLocation];
    }
	
	
	
}

-(void)savePreferences {
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    
    if ((![initialLogLocation isEqualToString:[locationField stringValue]]) 
		|| (initialLogFormat != [formatPopUp indexOfSelectedItem])){
		BOOL isDir = NO;
		NSMutableDictionary *userStatsDict = nil;
		NSNumber *zero = [[NSNumber alloc] initWithInt:0];
		if ([[NSFileManager defaultManager] fileExistsAtPath:initialLogLocation isDirectory:&isDir])
		{
			if (!isDir)
				[[NSFileManager defaultManager] removeFileAtPath:initialLogLocation handler:nil];
		}
	
		if ((userStatsDict = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPStatsFile]) != nil)
		{
			[userStatsDict setObject:zero forKey:LASTLINE];
		}
		else
		{
			userStatsDict = [[NSMutableDictionary alloc] initWithObjects:[NSArray arrayWithObject:zero] 
																 forKeys:[NSArray arrayWithObject:LASTLINE]];
		}
    
		[userStatsDict writeToFile:PureFTPStatsFile atomically:YES];
		[userStatsDict release];
		[zero release];
	}
	 
    NSNumber *logOnOff = [[NSNumber alloc] initWithInt:[logSwitch state]];  
    NSNumber *updateOnOff = [[NSNumber alloc] initWithInt:[updateSwitch state]]; 
    NSNumber *shareOnOff = [[NSNumber alloc] initWithInt:[shareSwitch state]]; 
    
	NSNumber *statsConvertState = [[NSNumber alloc] initWithInt:[convertSwitch state]];
	NSNumber *statsShowDetails = [[NSNumber alloc] initWithInt:[detailOutputSwitch state]];
	NSNumber *statsFormat = [[NSNumber alloc] initWithInt:[statFormatPopUp indexOfSelectedItem]];
	NSNumber *statsDays = [[NSNumber alloc] initWithInt:[daysPopUp indexOfSelectedItem]];
	NSString *statsLocation = [NSString stringWithString:[saveToField stringValue]];
	NSString *stime = [NSString stringWithFormat:@"%d:%d", [time hour], [time minute]];
	
	[preferences setObject:statsConvertState forKey:PureFTPStatsConvertState];
	[preferences setObject:statsFormat forKey:PureFTPStatsConvertFormat];
	[preferences setObject:statsShowDetails forKey:PureFTPStatsConvertShowDetail];
	[preferences setObject:statsDays forKey:PureFTPStatsConvertDays];
	[preferences setObject:stime forKey:PureFTPStatsConvertTime];
	[preferences setObject:statsLocation forKey:PureFTPStatsConvertLocation];
	
    [preferences setObject:logOnOff forKey:PureFTPLogOnOff]; 
    [preferences setObject:updateOnOff forKey:PureFTPLogAutoUpdate]; 
    [preferences setObject:shareOnOff forKey:PureFTPLogNiceThread]; 
    
    [preferences setObject:[formatPopUp titleOfSelectedItem] forKey:PureFTPLogFormat];
    [preferences setObject:[locationField stringValue] forKey:PureFTPLogLocation];
    
    
    NSNumber *update = [[NSNumber alloc] initWithInt:1];
    [preferences setObject:update forKey:PureFTPPrefsUpdated];
    
    //NSLog(@"Saving PureFTPD preferences - Logging Facilities");
    [preferences writeToFile:PureFTPPreferenceFile atomically:YES];
    
    [logOnOff release];
	[updateOnOff release];
	[shareOnOff release];
	[statsConvertState release];
    [statsShowDetails release];
	[statsFormat release];
	[statsDays release];
	
    [update release];
   
    [preferences release];
    
	[self updateCronEntry];
	modified = NO;
}

- (void)controlTextDidBeginEditing:(NSNotification *)aNotification
{
    modified = YES;
}


    
- (IBAction)chooseFile:(id)sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	if ([oPanel respondsToSelector:@selector(setCanCreateDirectories:)])
		[oPanel setCanCreateDirectories:YES];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:YES];
    [oPanel setResolvesAliases:NO];
    
	NSString *path = [[locationField stringValue] stringByDeletingLastPathComponent];
	BOOL isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]
		|| !isDir)
		path=@"/"; 
	[oPanel beginSheetForDirectory:path file:nil types:nil 
		    modalForWindow:[NSApp mainWindow]
		     modalDelegate: self
		    didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo: nil];
    
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
    [NSApp stopModal];
    if (returnCode == NSOKButton){
        NSString *logfile = [[sheet filenames] objectAtIndex:0];
        BOOL isDir = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:logfile isDirectory:&isDir])
        {
            if (isDir)
                logfile = [logfile stringByAppendingPathComponent:@"pureftpd.log"];
        }
        
        [locationField setStringValue: logfile];
    }
    modified = YES;
}

- (IBAction)didModify:(id)sender
{
    if (sender == logSwitch)
    {
		if ([sender state] == 1)
		{
			[formatPopUp setEnabled:YES];
			[locationField setEnabled:YES];
			[browseButton setEnabled:YES];
			[updateSwitch setEnabled:YES];
			[shareSwitch setEnabled:YES];
			[convertSwitch setEnabled:YES];
		}
		else
		{
			[formatPopUp setEnabled:NO];
			[locationField setEnabled:NO];
			[browseButton setEnabled:NO];
			[updateSwitch setEnabled:NO];
			[shareSwitch setEnabled:NO];
			[convertSwitch setEnabled:NO];
		}
		
		[self toggleConvertion:convertSwitch];
    }
    
    modified = YES;  
}

- (IBAction)chooseDir:(id)sender
{
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	if ([oPanel respondsToSelector:@selector(setCanCreateDirectories:)])
		[oPanel setCanCreateDirectories:YES];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:NO];
    [oPanel setResolvesAliases:NO];
    
	NSString *path = [saveToField stringValue];
	BOOL isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]
		|| !isDir)
		path=@"/";
		
    [oPanel beginSheetForDirectory:path file:nil types:nil 
		    modalForWindow:[NSApp mainWindow]
		     modalDelegate: self
		    didEndSelector: @selector(chooseDir:returnCode:contextInfo:)
                       contextInfo: nil];
}

- (void)chooseDir:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
    [NSApp stopModal];
    if (returnCode == NSOKButton){
        NSString *logfile = [[sheet filenames] objectAtIndex:0];
        
        [saveToField setStringValue: logfile];
    }
	
	modified = YES;
}

- (IBAction)preview:(id)sender
{
	NSString *tmpDir = [NSString stringWithString:@"/tmp/purestats/"];
	// make sure dir exists
	[[NSFileManager defaultManager] createDirectoryAtPath:tmpDir attributes:nil];
	
	int format=[statFormatPopUp indexOfSelectedItem]; // 0: HTML / 1: CSV
	int details = [detailOutputSwitch state]; // 0: no details / 1: with details (only for HTML output)
	
	NSTask *ps = [[NSTask alloc] init];
	[ps setLaunchPath:PureStatsCMD];
	if (format)
	{
		[ps setArguments:[NSArray arrayWithObjects:@"-c", @"-o", tmpDir, nil]];
	} else {
		if (details)
			[ps setArguments:[NSArray arrayWithObjects:@"-m", @"-d", @"-f", @"-o", tmpDir, nil]];
		else 
			[ps setArguments:[NSArray arrayWithObjects:@"-m", @"-f", @"-o", tmpDir, nil]];
	}
	
	[ps launch];
	[ps waitUntilExit];
	[ps release];
	
	if (format)
		[[NSWorkspace sharedWorkspace] openFile:tmpDir];
	else
		[[NSWorkspace sharedWorkspace] openFile:[NSString stringWithFormat:@"%@/index.html", tmpDir]];
}

- (IBAction)toggleConvertion:(id)sender
{
	if ([sender state]==1 && [sender isEnabled])
	{
		[browseDirButton setEnabled:YES];
		[detailOutputSwitch setEnabled:YES];
		[previewButton setEnabled:YES];
		[daysPopUp setEnabled:YES];
		[statFormatPopUp setEnabled:YES];
		[saveToField setEnabled:YES];
	} else {
		[browseDirButton setEnabled:NO];
		[detailOutputSwitch setEnabled:NO];
		[previewButton setEnabled:NO];
		[daysPopUp setEnabled:NO];
		[statFormatPopUp setEnabled:NO];
		[saveToField setEnabled:NO];
	}
	
	modified = YES;
}

- (void)updateCronEntry
{
	NSString *crontab = [NSString stringWithString:@"/etc/crontab"];
	NSString *cronContents = [NSString stringWithContentsOfFile:crontab];
	
	NSMutableString *purestats = [[NSMutableString alloc] init];
	NSString *args = nil;
	int format=[statFormatPopUp indexOfSelectedItem]; // 0: HTML / 1: CSV
	int details = [detailOutputSwitch state]; // 0: no details / 1: with details (only for HTML output)
	
	if (format)
	{
		args = [NSString stringWithFormat:@"-c -o %@", [saveToField stringValue]];
	} else {
		if (details)
			args = [NSString stringWithFormat:@"-m -d -f -o %@", [saveToField stringValue]];
		else 
			args = [NSString stringWithFormat:@"-m -f -o %@", [saveToField stringValue]];
	}
	NSString *dow = nil;
	int d = [daysPopUp indexOfSelectedItem];
	if (d == 0)
		dow = [NSString stringWithFormat:@"*"];
	else 
		dow = [NSString stringWithFormat:@"%d", d];
		
	NSString *min = [NSString stringWithFormat:@"%d", [time minute]];
	NSString *hour = [NSString stringWithFormat:@"%d", [time hour]];
	
	[purestats appendFormat:@"%@\t%@\t*\t*\t%@\troot %@ %@", min, hour, dow, PureStatsCMD, args];
	
	// remove previous entry if exists
	NSRange pRange = [cronContents rangeOfString:PureStatsCMD];
	if (pRange.length != 0)
	{
		// found
		NSRange lineRange = [cronContents lineRangeForRange:pRange];
        NSString *before = [NSString stringWithString:[cronContents substringToIndex:lineRange.location]];
        NSString *after = [NSString stringWithString:[cronContents substringFromIndex:NSMaxRange(lineRange)]];
        
        cronContents = [NSString stringWithFormat:@"%@%@", before, after];
	}
	
	if ([convertSwitch state])
	{
		cronContents = [cronContents stringByAppendingFormat:@"%@\n", purestats];
	}
	
	[cronContents writeToFile:crontab atomically:YES];
	
	// reload cron daemon
	 UInt32          response;

    OSStatus err = Gestalt(gestaltSystemVersion, (SInt32 *) &response);
    
    if (response >= 0x01040) {
		// launchd
		NSTask *unload = [[NSTask alloc] init];
		[unload setLaunchPath:@"/bin/launchctl"];
		[unload setArguments:[NSArray arrayWithObjects:@"unload", @"-w", @"/System/Library/LaunchDaemons/com.vix.cron.plist", nil]];
		[unload launch];
		[unload waitUntilExit];
		[unload release];
		NSTask *load = [[NSTask alloc] init];
		[load setLaunchPath:@"/bin/launchctl"];
		[load setArguments:[NSArray arrayWithObjects:@"load", @"-w", @"/System/Library/LaunchDaemons/com.vix.cron.plist", nil]];
		[load launch];
		[load release];
	} else {
		kvm_t *kd;
		char errbuf[256];
		struct kinfo_proc *kp;
		int i, nentries;
		char* cmd;
		pid_t pid;
		int result = -1;
    
    
		kd = kvm_openfiles(0, 0, 0, O_RDONLY, errbuf);
		if (kd != 0)
		{
			if ((kp = kvm_getprocs(kd, KERN_PROC_ALL, 0, &nentries)) != 0)
			{
				for (i = 0; i < nentries; i++) {
					cmd = kp[i].kp_proc.p_comm;
					pid = kp[i].kp_proc.p_pid;
					if (!strcmp("cron", cmd)) {
						result = pid;
					}	
				}
				kvm_close(kd);
			}
		}
    
		
		
		if (result != -1)
		{
			kill(result, SIGHUP);
		}
	}
	
	[purestats release];
	
}

@end
