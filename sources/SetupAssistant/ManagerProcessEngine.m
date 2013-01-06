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


#import "ManagerProcessEngine.h"
#include <stdio.h>
#include <fcntl.h>
#include <kvm.h>
#include <sys/param.h>
#include <sys/sysctl.h>
#include <unistd.h>

@implementation ManagerProcessEngine

-(id) init
{
    self = [super init];
    if (self)
    {
        allOptions = [[NSMutableDictionary alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"allOptions" ofType:@"plist"]];
		
		wizardOptions = [[NSMutableDictionary alloc] init];
        settingsReview = [[NSString alloc] initWithString:@""];
    }
    return self;
}

-(void) dealloc 
{
    [allOptions release];
    [wizardOptions release];
    [super dealloc];
}


-(NSMutableDictionary *) allOptions
{
    return allOptions;
}

-(NSMutableDictionary *) wizardOptions
{
    return wizardOptions;
}

-(NSString*) settingsReview
{
    settingsReview = @"";
    settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"Take a moment to review your Pure-FTPd Manager settings", @"Review PureFTPd Settings")];
    settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"\n\nAnonymous Access:\n", @"Anonymous access")];
    if ([[wizardOptions objectForKey:ANONSKIP] intValue] == 1)
        settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"\t Skipping Anonymous access setup ...", @"Skip anonymous configuration")];
    else
    {
        settingsReview = [settingsReview stringByAppendingFormat:NSLocalizedString(@"\tUsername:  ftp\n\tUID:  %d\n\tHome:  %@\n\tMember of:  %d", @"ftp account information"), 
            [[wizardOptions objectForKey:ANONUID] intValue], [wizardOptions objectForKey:ANONHOME], [[wizardOptions objectForKey:ANONGROUP] intValue]];
    }
    
    settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"\n\nVirtual Users:\n", @"Virtual Users")];
     if ([[wizardOptions objectForKey:VUSKIP] intValue] == 1)
     {
         settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"\t Skipping Virtual Users setup ...", @"Skip virtual Users")];
     }
     else
     {
         settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@" - Virtual users will be affiliated to the following system user : \n", @"VUsers information")];
         settingsReview = [settingsReview stringByAppendingFormat:NSLocalizedString(@"\tUsername:  %@\n\tUID:  %d\n", @"VUsers details"), 
             [wizardOptions objectForKey:VULOGIN], [[wizardOptions objectForKey:VUUID] intValue]];
         settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@" - Their system group will be set to\n", @"VUsers Group")];
         settingsReview = [settingsReview stringByAppendingFormat:NSLocalizedString(@"\tGroup:  %@\n\tGID:  %d\n", @"VUsers Group details"), 
             [wizardOptions objectForKey:VUGROUP], [[wizardOptions objectForKey:VUGID] intValue] ];
         settingsReview = [settingsReview stringByAppendingFormat:NSLocalizedString(@" - Default base directory for virtual users:\n\t %@", @"VUsers Base directory"), 
             [wizardOptions objectForKey:VUHOME]];
     }
     
    settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"\n\nServer logging:\n", @"Server Logging facilities")];
    if ([[wizardOptions objectForKey:LOGSTATE] intValue] == 0)
        settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"\t Skipping server statistics configuration...", @"Skip server logging")];
    else
    {
        settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"\t - Record server statistics configuration...\n", @"server stats configuration")];
        if ([[wizardOptions objectForKey:LOGNICE] intValue] == 1)
            settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"\t - Share processor time between running applications\n", @"Share processor time")];
        if ([[wizardOptions objectForKey:LOGUPDATE] intValue] == 1)
            settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"\t - Statistics automatically updated at PureFTPd Manager startup\n", @"Auto update stats at startup")];
    }
    
    settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"\n\nVirtual Hosts:\n", @"Virtual hosts")];
    settingsReview = [settingsReview stringByAppendingFormat:NSLocalizedString(@" - Default base directory for virtual hosts:\n\t %@", @"VHosts base directory"),  [wizardOptions objectForKey:VHHOME]];
        
    settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"\n\nSystem settings:\n", @"System settings")];
    if ([[wizardOptions objectForKey:ATSTARTUP] intValue] == 1)
        settingsReview = [settingsReview stringByAppendingString:NSLocalizedString(@"\t - Automatically start at PureFTPd at boot\n", @"Autostart at boot")];
        
    return settingsReview;
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
        if ( aUID == [uid intValue]){
/*            NSRunAlertPanel(NSLocalizedString(@"You specified a UID that already exists!",@"UID exists"),
                            NSLocalizedString(@"Please choose another one",@"Please choose another one"),
                            NSLocalizedString(@"Ok",@"Ok"),
                            @"",nil);*/
            return NO;
        }
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
        {
            /*NSRunAlertPanel(NSLocalizedString(@"You specified a GID that already exists!",@"GID exists"),
                            NSLocalizedString(@"Please choose another one",@"Please choose another one"),
                            NSLocalizedString(@"Ok",@"Ok"),
                            @"",nil);*/
            return NO;
        }
    }
    
    return YES;
}

-(BOOL) uniqUser:(NSString *) aUser
{
    NSMutableArray *myUsers = [NSMutableArray arrayWithArray:[self getSysUsers]];
    NSMutableDictionary *user;
    NSEnumerator *enumerate = [myUsers objectEnumerator];
    
    while (user = [enumerate nextObject])
    {
        NSString *uid = [NSString stringWithString:[user objectForKey:@"Username"]];
        if ( [aUser isEqualToString:uid]){
            if ([uid isEqualToString:@"ftp"])
            {
                /*NSRunAlertPanel(NSLocalizedString(@"Anonymous account already present.",@"Login screen name exists"),
                                NSLocalizedString(@"Anonymous account setup will be skipped",@"Anonymous account setup will be skipped"),
                                NSLocalizedString(@"Ok",@"Ok"),
                                @"",nil);*/
                return NO;
            }
            
            else{
             /*    NSRunAlertPanel(NSLocalizedString(@"You specified a login that already exists!",@"Login screen name exists"),
                            NSLocalizedString(@"Please choose another one",@"Please choose another one"),
                            NSLocalizedString(@"Ok",@"Ok"),
                            @"",nil);*/
                return NO;
            }
        }
    }
    
    return YES;
}

-(BOOL) uniqGroup:(NSString *) aGroup
{
    NSMutableArray *myGroups = [NSMutableArray arrayWithArray:[self getSysGroups]];
    NSMutableDictionary *group;
    NSEnumerator *enumerate = [myGroups objectEnumerator];
    
    while (group = [enumerate nextObject])
    {
       NSString *gid = [NSString stringWithString:[group objectForKey:@"Group"]];
        if ( [aGroup isEqualToString:gid])
        {
            /*NSRunAlertPanel(NSLocalizedString(@"You specified a group name that already exists!",@"Group name exists"),
                            NSLocalizedString(@"Please choose another one",@"Please choose another one"),
                            NSLocalizedString(@"Ok",@"Ok"),
                            @"",nil);*/
            return NO;
        }
    }
    
    return YES;
}


-(BOOL) checkUID:(int) aUID forUser:(NSString *)aUser
{
    NSMutableArray *myUsers = [NSMutableArray arrayWithArray:[self getSysUsers]];
    NSMutableDictionary *user;
    NSEnumerator *enumerate = [myUsers objectEnumerator];
    
    while (user = [enumerate nextObject])
    {
        NSString *name = [NSString stringWithString:[user objectForKey:@"Username"]];
        NSNumber *uid = [NSNumber numberWithInt:[[user objectForKey:@"UID"] intValue]];
         
        if ( [aUser isEqualToString:name] && (aUID == [uid intValue])){
            return YES;
        }
    }
    
    return NO;
}

-(BOOL) checkGID:(int) aGID forGroup:(NSString *)aGroup
{
    NSMutableArray *myUsers = [NSMutableArray arrayWithArray:[self getSysGroups]];
    NSMutableDictionary *user;
    NSEnumerator *enumerate = [myUsers objectEnumerator];
    
    while (user = [enumerate nextObject])
    {
        NSString *name = [NSString stringWithString:[user objectForKey:@"Group"]];
        NSNumber *gid = [NSNumber numberWithInt:[[user objectForKey:@"GID"] intValue]];
        
        if ( [aGroup isEqualToString:name] && (aGID == [gid intValue])){
            return YES;
        }
    }

    return NO;

}

- (void) addToStartup:(BOOL) onOff
{
	SInt32 MacVersion;
    Gestalt(gestaltSystemVersion, &MacVersion);
	
    NSString *hostConfig = [NSString stringWithContentsOfFile:@"/etc/hostconfig"];
    NSString *newConfig;
    NSRange pRange = [hostConfig rangeOfString:@"PUREFTPD"];
    NSString *isOn;
	NSString *isOnX; // disable for xinetd
    if (onOff){
        isOn = @"YES";
		isOnX = @"no";;
	}
    else{
        isOn=@"NO";
		isOnX = @"yes";
	}
            
    
    if (pRange.length==0) // Can't find entry in /etc/hostconfig; we add it
        newConfig = [NSString stringWithString:[hostConfig stringByAppendingFormat:@"\nPUREFTPD=-%@-\n", isOn]];
    else 
    {
        NSRange lineRange = [hostConfig lineRangeForRange:pRange];
        NSString *before = [NSString stringWithString:[hostConfig substringToIndex:lineRange.location]];
        NSString *after = [NSString stringWithString:[hostConfig substringFromIndex:NSMaxRange(lineRange)]];
        
        NSString *pStatus=[NSString stringWithFormat:@"PUREFTPD=-%@-\n", isOn];
        
        newConfig = [NSString stringWithFormat:@"%@%@%@", before, pStatus, after];
    }
    
    [newConfig writeToFile:@"/etc/hostconfig" atomically:YES];
	
	
	
	NSArray *args = [NSArray arrayWithArray:[self generateArguments]];
	if (MacVersion < 0x1040){
		NSString *ftpFile = [NSString stringWithFormat:@"service ftp\n\
{\n\
\tdisable = %@\n\
\tsocket_type = stream\n\
\twait = no\n\
\tuser = root\n\
\tserver = /usr/local/sbin/pure-ftpd\n\
\tserver_args = %@\n\
\tgroups = yes\n\
\tflags = REUSE\n}", isOnX, [args componentsJoinedByString:@" "]];
    
		[ftpFile writeToFile:@"/etc/xinetd.d/ftp" atomically:YES];
    
		int xinetdpid = -1;
    
		if ((xinetdpid = [self getXinetdPid]) != -1){
			//NSString *xinetdPID = [NSString stringWithContentsOfFile:@"/var/run/xinetd.pid"];
			kill(xinetdpid, SIGUSR2);
		} else {
			NSTask *xinetd = [[NSTask alloc] init];
			[xinetd setLaunchPath:@"/usr/sbin/xinetd"];
			NSArray *xargs = [NSArray arrayWithObjects:@"-inetd_compat", @"-pidfile", @"/var/run/xinetd.pid", nil];
			[xinetd setArguments:xargs];
			[xinetd launch];
			[xinetd release];
		}
		
	} else { // 10.4
		NSTask *pureFTPd = [[NSTask alloc] init]; //stop any active ftp
		[pureFTPd setLaunchPath:@"/bin/launchctl"];
		[pureFTPd setArguments:[NSArray arrayWithObjects:@"unload", @"-w", @"/System/Library/LaunchDaemons/ftp.plist",nil]];
		[pureFTPd launch];
		[pureFTPd release];
		
		NSMutableDictionary *launchDaemon = [NSMutableDictionary dictionaryWithContentsOfFile:@"/System/Library/LaunchDaemons/ftp.plist"];
		[launchDaemon setObject:@"org.pureftpd.macosx" forKey:@"Label"];
		[launchDaemon setObject:PureFTPDCMD forKey:@"Program"];
		[launchDaemon setObject:args forKey:@"ProgramArguments"];
		[launchDaemon writeToFile:@"/System/Library/LaunchDaemons/ftp.plist" atomically:YES];
		NSTask *_pureFTPd = [[NSTask alloc] init]; //start pure-ftpd
		[_pureFTPd setLaunchPath:@"/bin/launchctl"];
		[_pureFTPd setArguments:[NSArray arrayWithObjects:@"load", @"-w", @"/System/Library/LaunchDaemons/ftp.plist",nil]];
		[_pureFTPd launch];
		[_pureFTPd release];
	}
	
}

-(int) getXinetdPid 
{
    kvm_t *kd;
    char errbuf[256];
    struct kinfo_proc *kp;
    int i, nentries;
    char* cmd;
    pid_t pid;
    int result = -1;
    
    
    kd = kvm_openfiles(0, 0, 0, O_RDONLY, errbuf);
    if (kd == 0)
    {
        return result;
     	//printf("%s\n", errbuf);
    }
    
    if ((kp = kvm_getprocs(kd, KERN_PROC_ALL, 0, &nentries)) == 0)
    {
        return result;
        //printf("%s\n", kvm_geterr(kd));
    }
    
    for (i = 0; i < nentries; i++) {
    	cmd = kp[i].kp_proc.p_comm;
        pid = kp[i].kp_proc.p_pid;
        if (!strcmp("xinetd", cmd)) {
            result = pid;
    	}
    }
    kvm_close(kd);
    
    return result;
}

-(NSMutableArray *) generateArguments 
{
    NSMutableDictionary *serverPreferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    NSMutableArray *arguments = [[[NSMutableArray alloc] init] autorelease];
    /* Prepare server arguments...
        
        ...from fields
        if (![[serverPreferences objectForKey:PureFTP] isEqualToString:@""])
    {
            [arguments addObject:@"-"];
            [arguments addObject:[serverPreferences objectForKey:PureFTP]];
    }
    
    ...from switches
        if ([[serverPreferences objectForKey:PureFTP] intValue] == 1)
    {
            [arguments addObject:@"-"];
    }
    */
    
    // Port
    /*if (![[serverPreferences objectForKey:PureFTPPort] isEqualToString:@""] && ([serverModePopUp indexOfSelectedItem] == 1))
    {	
        //NSNumber *port = [[NSNumber alloc] initWithInt:[ intValue]];
        [arguments addObject:@"-S"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPPort]];
    }*/
    
    // Timeout
    if (![[serverPreferences objectForKey:PureFTPTimeout] isEqualToString:@""])
    {
        [arguments addObject:@"-I"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPTimeout]];
    }
    
    // PassiveRange
    if (![[serverPreferences objectForKey:PureFTPPassiveRange] isEqualToString:@""])
    {
        [arguments addObject:@"-p"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPPassiveRange]];
    }
    
    //Max Users
    if (![[serverPreferences objectForKey:PureFTPMaxUsers] isEqualToString:@""])
    {
        [arguments addObject:@"-c"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPMaxUsers]];
    }
    
    // Max sessions per IP
    if (![[serverPreferences objectForKey:PureFTPMaxSessions] isEqualToString:@""])
    {
        [arguments addObject:@"-C"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPMaxSessions]];
    }
    
    // FXP
    switch([[serverPreferences objectForKey:PureFTPFXP] intValue]){
        case 0:
            // FXPDisabled
            break;
        case 1:
        {
            // FXPEveryone
            [arguments addObject:@"-W"];
            break;
        }
        case 2:
        {
            // FXPAuthOnly
            [arguments addObject:@"-w"];
            break;
        }
    }
    
    // Rendezvous
    if ( (![[serverPreferences objectForKey:PureFTPRendezVous] isEqualToString:@""]) && ([[serverPreferences objectForKey:PureFTPServerMode] intValue] == 1) )
    {
        [arguments addObject:@"-v"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPRendezVous]];
    }
    
    // Resolve hostnames
    if ([[serverPreferences objectForKey:PureFTPResolvName] intValue] == 1)
    {
        [arguments addObject:@"-H"];
    }
    
    // Force Active Mode
    if ([[serverPreferences objectForKey:PureFTPForceActive] intValue] == 1)
    {
        [arguments addObject:@"-N"];
    }
    
    // Force IP
    if (![[serverPreferences objectForKey:PureFTPForceIP] isEqualToString:@""])
    {
        [arguments addObject:@"-P"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPForceIP]];
    }
    
    // Disk usage
    if (![[serverPreferences objectForKey:PureFTPMaxPartition] isEqualToString:@""])
    {
        [arguments addObject:@"-k"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPMaxPartition]];
    }
    
    // Max Load
    if (![[serverPreferences objectForKey:PureFTPMaxLoad] isEqualToString:@""])
    {
        [arguments addObject:@"-m"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPMaxLoad]];
    }
    
    // User Speed Limit
    if (![[serverPreferences objectForKey:PureFTPUserSpeedLimit] isEqualToString:@""])
    {
        [arguments addObject:@"-T"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPUserSpeedLimit]];
    }
    
	//Recursion Limit
	NSString *rl = [serverPreferences objectForKey:PureFTPRecursionLimit];
    if ((rl != nil) && ([rl length] > 0))
    {
        [arguments addObject:@"-L"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPRecursionLimit]];
    }
	
    // Extra Args
    if (![[serverPreferences objectForKey:PureFTPExtraArguments] isEqualToString:@""])
    {
        [arguments addObject:[serverPreferences objectForKey:PureFTPExtraArguments]];
    }
    
    // Auth methods
    NSMutableArray *authMethods = [NSArray arrayWithArray:[serverPreferences objectForKey:PureFTPAuthentificationMethods]];
    NSMutableDictionary *authDict;
    NSEnumerator *myEnumerator = [authMethods objectEnumerator];
    
    while (authDict = [myEnumerator nextObject])
    {
        if ([[authDict objectForKey:@"auth.type"] isEqualToString:@"PureDB"]){
            NSString *authArg = [NSString stringWithFormat:@"-lpuredb:%@", [authDict objectForKey:@"auth.file"]];
            [arguments addObject:authArg];
        }
        else if ([[authDict objectForKey:@"auth.type"] isEqualToString:@"LDAP"]){
            NSString *authArg = [NSString stringWithFormat:@"-lldap:%@", [authDict objectForKey:@"auth.file"]];
            [arguments addObject:authArg];
        }
        else if ([[authDict objectForKey:@"auth.type"] isEqualToString:@"MySQL"]){
            NSString *authArg = [NSString stringWithFormat:@"-lmysql:%@", [authDict objectForKey:@"auth.file"]];
            [arguments addObject:authArg];
        }
        else if ([[authDict objectForKey:@"auth.type"] isEqualToString:@"PostgreSQL"]){
            NSString *authArg = [NSString stringWithFormat:@"-lpgsql:%@", [authDict objectForKey:@"auth.file"]];
            [arguments addObject:authArg];
        }
        else if ([[authDict objectForKey:@"auth.type"] isEqualToString:@"Unix"]){
	    // Jaguar compatible 
            NSString *authArg = [NSString stringWithString:@"-lunix"];
            [arguments addObject:authArg];
        }
        else if ([[authDict objectForKey:@"auth.type"] isEqualToString:@"PAM"]){
	    // Panther compatible 
            NSString *authArg = [NSString stringWithString:@"-lpam"];
            [arguments addObject:authArg];
        }
    }
    
    
    // Create homedir automatically
    if ([[serverPreferences objectForKey:PureFTPCreateHomeDir] intValue] == 1)
    {
        [arguments addObject:@"-j"];
    }
    
    // Disable anonymous access
    if ([[serverPreferences objectForKey:PureFTPNoAnonymous] intValue] == 1)
    {
        [arguments addObject:@"-E"];
    }
    
    // Disable upload for anonymous users
    if ([[serverPreferences objectForKey:PureFTPAnonymousNoUpload] intValue] == 1)
    {
        [arguments addObject:@"-i"];
    }
    
    // Anonymous can create dir
    if ([[serverPreferences objectForKey:PureFTPAnonymousCreateDir] intValue] == 1)
    {
        [arguments addObject:@"-M"];
    }
    
    // Anonymous can't dld files owned by anonymous
    if ([[serverPreferences objectForKey:PureFTPAnonymousNoDownload] intValue] == 1)
    {
        [arguments addObject:@"-s"];
    }
    
    // Anonymous Ratio 
    if (![[serverPreferences objectForKey:PureFTPAnonymousRatio] isEqualToString:@""])
    {
        [arguments addObject:@"-q"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPAnonymousRatio]];
    }
    
    // Anonymous speed limit
    if (![[serverPreferences objectForKey:PureFTPAnonymousSpeedLimit] isEqualToString:@""])
    {
        [arguments addObject:@"-t"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPAnonymousSpeedLimit]];
    }
    
    // Log Format
    if ([[serverPreferences objectForKey:PureFTPLogOnOff] intValue] == 1)
    {   
	NSString *logOptions = [NSString stringWithFormat:@"-O%@:%@", 
	    [[serverPreferences objectForKey:PureFTPLogFormat] lowercaseString], 
	    [serverPreferences objectForKey:PureFTPLogLocation]];
        //[arguments addObject:@"-O"];
	[arguments addObject:logOptions];
    }
    
    // TLS Behaviour PureFTPTLSBehaviour
    if (![[serverPreferences objectForKey:PureFTPTLSBehaviour] isEqualToString:@""])
    {
	[arguments addObject:@"-Y"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPTLSBehaviour]];
    }
    
	// Umask setting
	NSString *fileMask = nil;
	NSString *folderMask = nil;
	
	if ( ((fileMask = [serverPreferences objectForKey:PureFTPFileCreationMask]) != nil) &&
		 ((folderMask = [serverPreferences objectForKey:PureFTPFolderCreationMask]) !=nil) )
	{
		[arguments addObject:@"-U"];
		[arguments addObject:[NSString stringWithFormat:@"%@:%@", fileMask, folderMask]];
	}

	
    [serverPreferences release];
    return arguments;
    
    
}

-(void)createAnonymousUser
{
	NSMutableString *pwFile = [NSMutableString stringWithContentsOfFile:@"/private/etc/passwd"];
	NSString *anonymous = [NSString stringWithFormat:@"ftp:*:%@:99:Anonymous FTP User:%@:/usr/bin/false\n", 
							[wizardOptions objectForKey:ANONUID],
							[wizardOptions objectForKey:ANONHOME]];
							
	[pwFile appendString:anonymous];
	[pwFile writeToFile:@"/private/etc/passwd" atomically:YES];
	
}

-(void)createFTPVirtualUser
{
	NSMutableString *pwFile = [NSMutableString stringWithContentsOfFile:@"/private/etc/passwd"];
	NSString *ftpvirtual = [NSString stringWithFormat:@"%@:*:%d:%d:FTPVirtual User:/etc/pure-ftpd:/usr/bin/false\n", 
							[wizardOptions objectForKey:VULOGIN],
							[[wizardOptions objectForKey:VUUID] intValue],
							[[wizardOptions objectForKey:VUGID] intValue]];
							
	[pwFile appendString:ftpvirtual];
	[pwFile writeToFile:@"/private/etc/passwd" atomically:YES];
}

-(void)createFTPVirtualGroup
{
	NSMutableString *grpFile = [NSMutableString stringWithContentsOfFile:@"/private/etc/group"];
	NSString *ftpvirtual = [NSString stringWithFormat:@"%@:*:%d:%@\n", 
							[wizardOptions objectForKey:VUGROUP],
							[[wizardOptions objectForKey:VUGID] intValue],
							[wizardOptions objectForKey:VULOGIN]];
							
	[grpFile appendString:ftpvirtual];
	[grpFile writeToFile:@"/private/etc/group" atomically:YES];
	
	//ftpgroup:*:1982:ftpvirtual
	//[wizardOptions objectForKey:VUGROUP]
	//[[wizardOptions objectForKey:VUGID] intValue]
	//[[wizardOptions objectForKey:VUUID] intValue]
}

- (void) startProcess
{
    NSString *shellScript = [NSString stringWithString:@"#!/bin/sh\n"];
    NSString *anonScript = [NSString stringWithString:@"# Anonymous Account:\n"];
    NSString *vusersScript = [NSString stringWithString:@"\n# Virtual Users system account\n"];
    NSString *mkdirScript = [NSString stringWithString:@"\n# Creating Folders\n"];
    SInt32 MacVersion;
    Gestalt(gestaltSystemVersion, &MacVersion);
	
    if ([[wizardOptions objectForKey:ANONSKIP] intValue] == 1)
    {
        anonScript = [anonScript stringByAppendingString:@"# \t Skipping Anonymous access setup ..."];
        shellScript = [shellScript stringByAppendingString:anonScript];
    }
    else
    {
		//if (MacVersion < 0x1040){
			anonScript = [anonScript stringByAppendingFormat:@"niutil -create / /users/ftp \n niutil -createprop / /users/ftp expire 0 \n niutil -createprop / /users/ftp realname \"Anonymous FTP user\" \n niutil -createprop / /users/ftp name ftp \n niutil -createprop / /users/ftp passwd '*' \n niutil -createprop / /users/ftp change 0 \n niutil -createprop / /users/ftp home \"%@\" \n niutil -createprop / /users/ftp uid %@ \n niutil -createprop / /users/ftp gid %@ \n niutil -createprop / /users/ftp shell /dev/null \n\n" , 
				[wizardOptions objectForKey:ANONHOME], [wizardOptions objectForKey:ANONUID], [wizardOptions objectForKey:ANONGROUP]];
        /*} else {
			//[self createAnonymousUser];
		}*/
        anonScript = [anonScript stringByAppendingFormat:@"mkdir -p \"%@\"\n chmod 755 \"%@\" \n chown root:wheel \"%@\"\n chmod 555 \"%@\"\n chown ftp:%@ \"%@\"\n mkdir \"%@\"\n chmod 755 \"%@\"\n chown ftp:%@ \"%@\"", 
            [wizardOptions objectForKey:ANONHOME], 
            [[wizardOptions objectForKey:ANONHOME] stringByDeletingLastPathComponent],
            [[wizardOptions objectForKey:ANONHOME] stringByDeletingLastPathComponent],
            [wizardOptions objectForKey:ANONHOME],
            [wizardOptions objectForKey:ANONGROUP],
            [wizardOptions objectForKey:ANONHOME],
            [[wizardOptions objectForKey:ANONHOME] stringByAppendingPathComponent:@"incoming"],
            [[wizardOptions objectForKey:ANONHOME] stringByAppendingPathComponent:@"incoming"],
            [wizardOptions objectForKey:ANONGROUP],
            [[wizardOptions objectForKey:ANONHOME] stringByAppendingPathComponent:@"incoming"]];
        shellScript = [shellScript stringByAppendingString:anonScript];
    }
    
    if ([[wizardOptions objectForKey:VUSKIP] intValue] == 1)
    {
        vusersScript = [vusersScript stringByAppendingString:@"#\t Skipping Virtual Users Setup ..."];
         shellScript = [shellScript stringByAppendingString:vusersScript];
    }
    else
    {
		//if (MacVersion < 0x1040){
			NSString *userRef = [NSString stringWithFormat:@"/users/%@", [wizardOptions objectForKey:VULOGIN]];
			vusersScript = [vusersScript stringByAppendingFormat:@"niutil -create / %@\n niutil -createprop / %@ expire 0 \n niutil -createprop / %@ realname \"Virtual users account\" \n niutil -createprop / %@ name %@ \n niutil -createprop / %@ passwd '*' \n niutil -createprop / %@ change 0 \n niutil -createprop / \"%@\" home /dev/null \n niutil -createprop / %@ uid %d \n niutil -createprop / %@ gid %d \n niutil -createprop / %@ shell /etc/pure-ftpd\n", 
					userRef, userRef, userRef, userRef, [wizardOptions objectForKey:VULOGIN], userRef, userRef, userRef, userRef, [[wizardOptions objectForKey:VUUID] intValue], userRef, [[wizardOptions objectForKey:VUGID] intValue], userRef];
    
			NSString *groupRef = [NSString stringWithFormat:@"/groups/%@", [wizardOptions objectForKey:VUGROUP]];
			vusersScript = [vusersScript stringByAppendingFormat:@"niutil -create / %@ \n niutil -createprop / %@ passwd '*'\n niutil -createprop / %@ gid %d\n niutil -createprop / %@ users %@", 
					groupRef, groupRef, groupRef, 
					[[wizardOptions objectForKey:VUGID] intValue], groupRef, [wizardOptions objectForKey:VULOGIN]];
    
			shellScript = [shellScript stringByAppendingString:vusersScript];
		/*} else {
			[self createFTPVirtualUser];
			[self createFTPVirtualGroup];
		}*/
       
    }
	
	 mkdirScript = [mkdirScript stringByAppendingFormat:@"mkdir -p \"%@\"\n chown %@:%@ \"%@\"\n chmod 555 %@\n mkdir -p \"%@\"", 
            [wizardOptions objectForKey:VUHOME], 
            [wizardOptions objectForKey:VULOGIN], 
            [wizardOptions objectForKey:VUGROUP], 
            [wizardOptions objectForKey:VUHOME], 
            [wizardOptions objectForKey:VUHOME], 
            [wizardOptions objectForKey:VHHOME]];
    
    
        shellScript = [shellScript stringByAppendingString:mkdirScript];
   
    //NSLog(@"%@", shellScript);
    if (MacVersion >= 0x1040)
	{
		shellScript = [shellScript stringByAppendingString:@"\nrm -f /etc/xinetd.d/ftp\n"];
		shellScript = [shellScript stringByAppendingString:@"\n/usr/sbin/lookupd -flushcache"];
		//shellScript = [shellScript stringByAppendingString:@"\n/bin/launchctl unload -w /System/Library/LaunchDaemons/ftp.plist"];
	}
	
    [shellScript writeToFile:@"/tmp/Pure-FTPd.sh" atomically:YES];
    NSTask *setup = [[NSTask alloc] init];
    [setup setArguments:[NSMutableArray arrayWithObjects:@"/tmp/Pure-FTPd.sh", nil]];
    [setup setLaunchPath:@"/bin/sh"];
    [setup launch];
    [setup release];
    
}

- (BOOL) endProcess
{
    //NSLog(@"End Process");
    SInt32 MacVersion;
    
	NSMutableDictionary *prefs = nil;
        
	NSString *parentBundlePath = [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
	NSBundle *theManager = [NSBundle bundleWithPath:[parentBundlePath stringByDeletingLastPathComponent]];
	NSMutableDictionary *defaultPrefs = [NSMutableDictionary dictionaryWithContentsOfFile:[theManager pathForResource:@"basePreferences" ofType:@"plist"]];
	
        if (![[NSFileManager defaultManager] fileExistsAtPath:@"/private/etc/pure-ftpd"])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:@"/private/etc/pure-ftpd" attributes:nil];
        }
        
	NSString *currentVersionNumber = [[theManager infoDictionary] objectForKey:@"CFBundleVersion"];
	NSNumber *allowPam = [NSNumber numberWithInt:[[wizardOptions objectForKey:@"ALLOWPAM"] intValue]];
	
	// Merge Preferences
	if (![[NSFileManager defaultManager] fileExistsAtPath:PureFTPPreferenceFile]){
            // Get user system version
			
            if (Gestalt(gestaltSystemVersion, &MacVersion) == noErr)
            {
                [defaultPrefs setObject:[NSNumber numberWithInt:MacVersion] forKey:OSVersion];
                NSMutableArray *authMethods = [defaultPrefs objectForKey:PureFTPAuthentificationMethods];
                if (MacVersion >= 0x1030)
                {
                    
                    [authMethods removeAllObjects];
                    NSDictionary *pureDB = [NSDictionary dictionaryWithObjects:
                        [NSArray arrayWithObjects:@"PureDB", 
                            @"/etc/pure-ftpd/pureftpd.pdb", nil] 
                                                                       forKeys:[NSArray arrayWithObjects:@"auth.type", 
                                                                           @"auth.file", nil]];
                    NSDictionary *PAM = [NSDictionary dictionaryWithObjects:
                        [NSArray arrayWithObjects:@"PAM", @"/etc/pam.d/pure-ftpd", nil] 
                                                                    forKeys:[NSArray arrayWithObjects:@"auth.type", 
                                                                        @"auth.file", nil]];
                    
                    [authMethods addObject:pureDB];
					
                    if ( [allowPam intValue] == 1){
						[authMethods addObject:PAM];
					}
                    
                }
                else
                {
                    [authMethods removeAllObjects];
                    NSDictionary *pureDB = [NSDictionary dictionaryWithObjects:
                        [NSArray arrayWithObjects:@"PureDB", 
                            @"/etc/pure-ftpd/pureftpd.pdb", nil] 
                                                                       forKeys:[NSArray arrayWithObjects:@"auth.type", 
                                                                           @"auth.file", nil]];
                    NSDictionary *Unix = [NSDictionary dictionaryWithObjects:
                        [NSArray arrayWithObjects:@"Unix", @"", nil] 
                                                                     forKeys:[NSArray arrayWithObjects:@"auth.type", 
                                                                         @"auth.file", nil]];
                    
                    [authMethods addObject:pureDB];
					   if ( [allowPam intValue] == 1){
							[authMethods addObject:Unix];
					}
                }
                
            }
        [defaultPrefs writeToFile:PureFTPPreferenceFile atomically:NO];
	} else {
            NSDictionary *oldprefs = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];	
            NSArray *defaultKeys = [NSArray arrayWithArray:[oldprefs allKeys]];
            id key = nil;
            NSEnumerator *keyEnum = [defaultKeys objectEnumerator];
		
		
            while (key = [keyEnum nextObject]){
                    if (nil != [oldprefs objectForKey:key])
                        [defaultPrefs setObject:[oldprefs objectForKey:key] forKey:key];
            }
            [defaultPrefs writeToFile:PureFTPPreferenceFile atomically:NO]; 
	}
    
    prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
    [prefs setObject:[wizardOptions objectForKey:VUHOME] forKey:PureFTPUserBaseDir];
	[prefs setObject:[wizardOptions objectForKey:VUUID] forKey:@"PureFTPVirtualUID"];
	[prefs setObject:[wizardOptions objectForKey:VUGID] forKey:@"PureFTPVirtualGID"];
    [prefs setObject:[wizardOptions objectForKey:VHHOME] forKey:PureFTPVHostBaseDir];
	
    [prefs setObject:[NSNumber numberWithInt:[[wizardOptions objectForKey:ATSTARTUP] intValue]]
              forKey:PureFTPAtStartup];
    
    [prefs setObject:[NSNumber numberWithInt:[[wizardOptions objectForKey:LOGNICE] intValue]]
              forKey:PureFTPLogNiceThread];
    [prefs setObject:[NSNumber numberWithInt:[[wizardOptions objectForKey:LOGSTATE] intValue]]
              forKey:PureFTPLogOnOff];
    [prefs setObject:[NSNumber numberWithInt:[[wizardOptions objectForKey:LOGUPDATE] intValue]]
              forKey:PureFTPLogAutoUpdate];
	
	// add/remove pam | unix users
	NSMutableArray *authMethods = [prefs objectForKey:PureFTPAuthentificationMethods];
	NSEnumerator *authEnum = [authMethods objectEnumerator];
	NSDictionary *entry = nil;
	BOOL isPresent = NO;
	int index = 0;
	while ((entry = [authEnum nextObject]) !=nil){
		if (![allowPam intValue]){
			if ([[entry objectForKey:@"auth.type"] isEqualToString:@"PAM"] ||
				[[entry objectForKey:@"auth.type"] isEqualToString:@"Unix"] ){
					[authMethods removeObjectAtIndex:index];
					index--;
			}
			index++;
		} else {
			if ([[entry objectForKey:@"auth.type"] isEqualToString:@"PAM"] ||
				[[entry objectForKey:@"auth.type"] isEqualToString:@"Unix"] ){
					isPresent=YES;
				}
		}
	}
	if ([allowPam intValue] && !isPresent){
		NSDictionary *dict =nil;
		if (MacVersion >= 0x1030)
		{
			dict = [NSDictionary dictionaryWithObjects:
                        [NSArray arrayWithObjects:@"PAM", @"/etc/pam.d/pure-ftpd", nil] 
											   forKeys:[NSArray arrayWithObjects:@"auth.type", @"auth.file", nil]];
		} else {
			dict = [NSDictionary dictionaryWithObjects:
						[NSArray arrayWithObjects:@"Unix", @"", nil] 
											   forKeys:[NSArray arrayWithObjects:@"auth.type", @"auth.file", nil]];
		}
		[authMethods addObject:dict];
	}
	
	[prefs setObject:currentVersionNumber forKey:PureFTPPreferencesVersion];
    [prefs setObject:@"Done" forKey:@"wizardCompleted"];
	[prefs setObject:[NSNumber numberWithInt:1] forKey:@"ShowSplashWin"];
    
    
    
    if ([[prefs objectForKey:PureFTPRendezVous] isEqualToString:@"RDVAutoSet"])
        [prefs setObject:[NSString stringWithFormat:@"%@", [[NSProcessInfo processInfo] hostName]] forKey: PureFTPRendezVous];    
    
	[prefs setObject:[NSNumber numberWithInt:0] forKey:PureFTPServerMode];
	
    [prefs writeToFile:PureFTPPreferenceFile atomically:YES];
    
    // set file permissions
    NSNumber *posixPerm = [[NSNumber alloc] initWithInt:0600];
    NSMutableDictionary *attributes =[NSMutableDictionary dictionaryWithObject:posixPerm forKey:@"NSFilePosixPermissions"];
    [[NSFileManager defaultManager] changeFileAttributes:attributes atPath:PureFTPSSLCertificate];
    
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/etc/pure-ftpd/pureftpd.passwd"])
    {
        NSString *empty = @"";
        [empty writeToFile:@"/etc/pure-ftpd/pureftpd.passwd" atomically:YES];
        NSString *pdb = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"empty-pureftpd" ofType:@"pdb"]];
        [pdb writeToFile:@"/etc/pure-ftpd/pureftpd.pdb" atomically:YES];
    }
    
    if ([[wizardOptions objectForKey:ATSTARTUP] intValue])
         [self addToStartup:YES];
    else
        [self addToStartup:NO];
    
  
    // Launch the manager & quit
	
    NSTask *manager = [[NSTask alloc] init];
    [manager setLaunchPath:[parentBundlePath stringByAppendingPathComponent:@"MacOS/PureFTPd Manager"]];
    [manager launch];
    [manager release];
    
    return YES;
}


@end
