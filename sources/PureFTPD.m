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

#import "PureFTPD.h"
#include <stdio.h>
#include <fcntl.h>
#include <sys/param.h>
#include <sys/sysctl.h>
#include <unistd.h>

#include <sys/types.h>
#include <pwd.h>
#import <Cocoa/Cocoa.h>

@implementation PureFTPD

/*static bool pathForTool(CFStringRef toolName, char path[MAXPATHLEN])
{
    CFBundleRef bundle;
    CFURLRef resources;
    CFURLRef toolURL;
    Boolean success = true;
    
    bundle = CFBundleGetMainBundle();
    if (!bundle)
        return FALSE;
    
    resources = CFBundleCopyResourcesDirectoryURL(bundle);
    if (!resources)
        return FALSE;
    
    toolURL = CFURLCreateCopyAppendingPathComponent(NULL, resources, toolName, FALSE);
    CFRelease(resources);
    if (!toolURL)
        return FALSE;
    
    success = CFURLGetFileSystemRepresentation(toolURL, TRUE, (UInt8 *)path, MAXPATHLEN);
    
    CFRelease(toolURL);
    return !access(path, X_OK);
}*/

-(id) init
{
    self=[super init];
    if(self){
        pureFTPd=nil;
		Gestalt(gestaltSystemVersion, &MacVersion);
    }
    return self;
}

-(void) dealloc
{
   // [pureFTPd release];
    [super dealloc];
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
    
    if (![[serverPreferences objectForKey:PureFTPPort] isEqualToString:@""] && ([[serverPreferences objectForKey:PureFTPServerMode] intValue] == 1))
    {	
        //NSNumber *port = [[NSNumber alloc] initWithInt:[ intValue]];
        [arguments addObject:@"-S"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPPort]];
    }
    
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
    if (![[serverPreferences objectForKey:PureFTPRendezVous] isEqualToString:@""] && ([[serverPreferences objectForKey:PureFTPServerMode] intValue] == 1))
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
		if (MacVersion >= 0x1040){
			NSArray *extraArray = [[serverPreferences objectForKey:PureFTPExtraArguments] componentsSeparatedByString:@" "];
			NSEnumerator *myEnum = [extraArray objectEnumerator];
			NSString *arg = nil;
			while (nil !=(arg = [myEnum nextObject]))
			{
				[arguments addObject:arg];
			}
			
		} else {
			[arguments addObject:[serverPreferences objectForKey:PureFTPExtraArguments]];
		}
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
            
	    // Panther compatible 
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

-(BOOL)xinetdStatus
{
    if (![[NSFileManager defaultManager] fileExistsAtPath:@"/etc/xinetd.d/ftp"]){
        //NSLog(@"Can't locate xinetd ftp file");
        return NO;
    }
    NSString *xinetdFile = [NSString stringWithContentsOfFile:@"/etc/xinetd.d/ftp"];
    NSArray *lines = [xinetdFile componentsSeparatedByString:@"\n"];
    
    int xinetdPID = [self getXinetdPid];
    NSArray *onOff = [NSArray arrayWithArray:[[lines objectAtIndex:2] componentsSeparatedByString:@"="]];
    if ((onOff == nil) || ([onOff count] == 1))
    {
        //NSLog(@"Can't parse xinetd ftp file");
        return NO;
    }
    
    if ([[onOff objectAtIndex:1] isEqualToString:@" yes"] && (xinetdPID != -1)){
        //NSLog(@"xinetd ftp disabled");
        return NO;
    }  else if ([[onOff objectAtIndex:1] isEqualToString:@" no"] && (xinetdPID != -1)) {
        //NSLog(@"xinetd ftp not disabled");
        return YES;
    }

    return NO;
}


-(BOOL)standAloneStatus
{
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:PureFTPPIDFile]) {
      //  NSLog(@"standalone on");
        return YES;
    }
    //NSLog(@"standalone off");
    return NO;
}

-(BOOL)launchdStatus
{
	/*NSPipe *stdOut = [NSPipe pipe];
	NSFileHandle *handle;
	
	NSTask *launchctl = [[NSTask alloc] init];
	[launchctl setLaunchPath:@"/bin/launchctl"];
	[launchctl setStandardOutput:stdOut];
	[launchctl setArguments:[NSArray arrayWithObject:@"list"]];
	
	
	handle=[stdOut fileHandleForReading];
	
	
	[launchctl launch];
	
	BOOL isRunning = NO;
	NSString *string=[[NSString alloc] initWithData:
          [handle readDataToEndOfFile] encoding:NSASCIIStringEncoding];
	NSRange r = [string rangeOfString:@"org.pureftpd.macosx"];
	if (r.length == 19)
	{
		isRunning = YES;
	}
	
	[string release];
	[launchctl release];
	*/
	
	BOOL isRunning = NO;
	
	NSDictionary *launchdconfig = [NSDictionary dictionaryWithContentsOfFile:@"/System/Library/LaunchDaemons/ftp.plist"];
	if ([launchdconfig objectForKey:@"Disabled"] == nil || [[launchdconfig objectForKey:@"Disabled"] boolValue] == NO)
		isRunning = YES;
	
	return isRunning;
}

-(BOOL)isServerRunning
{
    NSDictionary *serverPreferences = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
    int serverMode = [[serverPreferences objectForKey:PureFTPServerMode] intValue];
    int serverModeModified = [[serverPreferences objectForKey:PureFTPServerModeModified] intValue];

    if (!serverMode && !serverModeModified){
		if (MacVersion >= 0x1040){
			return [self launchdStatus];
		} else { 
			return [self xinetdStatus];
		}
    } else if (serverMode && !serverModeModified){
        return [self standAloneStatus];
    } else if (!serverMode && serverModeModified){
        return [self standAloneStatus];
    } else if (serverMode && serverModeModified){
        return YES;
    }
    
    return NO;
}

-(void)restartServer{
    [self stopServer];
	[self startServer];
}

-(void)startServer
{
    NSMutableDictionary *serverPreferences = [NSMutableDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
    NSMutableArray *args = [[NSMutableArray alloc] initWithArray:[self generateArguments]];
	
	[serverPreferences setObject:[NSNumber numberWithInt:0] forKey:PureFTPServerModeModified];
	
    if ([[serverPreferences objectForKey:PureFTPServerMode] intValue]==1) {
        // StandAlone Mode
        pureFTPd = [[NSTask alloc] init];
        [pureFTPd setLaunchPath:PureFTPDCMD];
        [pureFTPd setArguments:args];
        [pureFTPd launch];
        [pureFTPd release];
    } else {
		
		if (MacVersion >= 0x1040){
			NSMutableDictionary *launchDaemon = [NSMutableDictionary dictionaryWithContentsOfFile:@"/System/Library/LaunchDaemons/ftp.plist"];
			[launchDaemon removeObjectForKey:@"Disabled"];
			[launchDaemon setObject:@"org.pureftpd.macosx" forKey:@"Label"];
			[args insertObject:PureFTPDCMD atIndex:0];
			[launchDaemon setObject:PureFTPDCMD forKey:@"Program"];
			[launchDaemon setObject:args forKey:@"ProgramArguments"];
			[launchDaemon writeToFile:@"/System/Library/LaunchDaemons/ftp.plist" atomically:YES];
			pureFTPd = [[NSTask alloc] init];
			[pureFTPd setLaunchPath:@"/bin/launchctl"];
			[pureFTPd setArguments:[NSArray arrayWithObjects:@"load", @"-w", @"/System/Library/LaunchDaemons/ftp.plist",nil]];
			[pureFTPd launch];
			[pureFTPd release];
		} else {
			NSString *ftpFile = [NSString stringWithFormat:@"service ftp\n\
{\n\
\tdisable = no\n\
\tsocket_type = stream\n\
\twait = no\n\
\tuser = root\n\
\tserver = /usr/local/sbin/pure-ftpd\n\
\tserver_args = %@\n\
\tgroups = yes\n\
\tflags = REUSE\n}", [args componentsJoinedByString:@" "]];

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
		}
    }
    // VHOST setup
    NSMutableArray *vhosts;
    if ([serverPreferences objectForKey:PureFTPVirtualHosts] != nil)
    {
        vhosts = [[NSMutableArray alloc] initWithArray:[serverPreferences objectForKey:PureFTPVirtualHosts]]; 
        NSEnumerator *vhostEnum = [vhosts objectEnumerator];
        NSMutableDictionary *vhostInfo;
        
        while (vhostInfo = [vhostEnum nextObject]){
            NSMutableArray *ifargs = [NSMutableArray arrayWithObjects:[vhostInfo objectForKey:@"vhost.nic"], 
                                                                    @"alias", [vhostInfo objectForKey:@"vhost.ip"],
                                                                    nil ]; 
            
            NSTask *ifconfig =[[NSTask alloc] init];
            [ifconfig setLaunchPath:@"/sbin/ifconfig"];	
            [ifconfig setArguments:ifargs];
            [ifconfig launch]; 
            [ifconfig release]; // alias created
        }
    }
	
	
    
	[serverPreferences writeToFile:PureFTPPreferenceFile atomically:NO];
    //[serverPreferences release];
    [vhosts release];
	[args release];
}

-(int) getXinetdPid 
{
	int mib[4] = { CTL_KERN, KERN_PROC, KERN_PROC_ALL, 0 };
	struct kinfo_proc *info;
	size_t length;
	int level, count, i;
	char* cmd;
    pid_t pid;
	
    int result = -1;
    
	// KERN_PROC_ALL has 3 elements
	level =  3;
	
	if (sysctl(mib, level, NULL, &length, NULL, 0) < 0)
		return -1;
	if (!(info = NSZoneMalloc(NULL, length)))
		return -1;
	if (sysctl(mib, level, info, &length, NULL, 0) < 0) {
		NSZoneFree(NULL, info);
		return -1;
	}
	
	// number of processes
	count = length / sizeof(struct kinfo_proc);
		
	for (i = 0; i < count; i++) {
	    cmd = info[i].kp_proc.p_comm;
        pid = info[i].kp_proc.p_pid;
        if (!strcmp("xinetd", cmd)) {
            result = pid;
    	}
	}
	
    NSZoneFree(NULL, info);

	
    return result;
}

-(void)stopStandAloneMode
{
    // StandAlone Mode
    if([[NSFileManager defaultManager] fileExistsAtPath:PureFTPPIDFile]){
        NSString *purePID = [NSString stringWithContentsOfFile:PureFTPPIDFile];
        kill([purePID intValue], SIGTERM);
        [[NSFileManager defaultManager] removeFileAtPath:PureFTPPIDFile handler:nil];
    }
}

-(void)stopXinetdMode
{
	NSMutableArray *args = [NSMutableArray arrayWithArray:[self generateArguments]];
	NSString *ftpFile = [NSString stringWithFormat:@"service ftp\n\
{\n\
\tdisable = yes\n\
\tsocket_type = stream\n\
\twait = no\n\
\tuser = root\n\
\tserver = /usr/local/sbin/pure-ftpd\n\
\tserver_args = %@\n\
\tgroups = yes\n\
\tflags = REUSE\n}", [args componentsJoinedByString:@" "]];
        
	[ftpFile writeToFile:@"/etc/xinetd.d/ftp" atomically:YES];
        int xinetdpid = -1;
	if ((xinetdpid = [self getXinetdPid]) != -1){
            //NSString *xinetdPID = [NSString stringWithContentsOfFile:@"/var/run/xinetd.pid"];
            kill(xinetdpid, SIGUSR2);
        } 
}

-(void)stopLaunchdMode
{
	pureFTPd = [[NSTask alloc] init];
	[pureFTPd setLaunchPath:@"/bin/launchctl"];
	[pureFTPd setArguments:[NSArray arrayWithObjects:@"unload", @"-w", @"/System/Library/LaunchDaemons/ftp.plist", nil]];
	[pureFTPd launch];
	[pureFTPd release];
}

-(void) stopServer{
    NSDictionary *serverPreferences = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];
    
	int serverMode = [[serverPreferences objectForKey:PureFTPServerMode] intValue];
    int serverModeModified = [[serverPreferences objectForKey:PureFTPServerModeModified] intValue];
    
	if (serverMode && !(serverModeModified)){
		[self stopStandAloneMode];
	} else if (serverMode && serverModeModified){
		if (MacVersion >= 0x1040){
			[self stopLaunchdMode];
		} else {
			[self stopXinetdMode];
		}
	} else if (!(serverMode) && !(serverModeModified)){
		if (MacVersion >= 0x1040){
			[self stopLaunchdMode];
		} else {
			[self stopXinetdMode];
		}
	} else if (!(serverMode) && serverModeModified) {
		[self stopStandAloneMode];
	}
	
    
    // remove aliases if any
    
    NSMutableArray *vhosts;
    if ([serverPreferences objectForKey:PureFTPVirtualHosts] != nil)
    {
        vhosts = [[NSMutableArray alloc] initWithArray:[serverPreferences objectForKey:PureFTPVirtualHosts]]; 
        NSEnumerator *vhostEnum = [vhosts objectEnumerator];
        NSMutableDictionary *vhostInfo;
        
        while (vhostInfo = [vhostEnum nextObject]){
            NSMutableArray *ifargs = [NSMutableArray arrayWithObjects:[vhostInfo objectForKey:@"vhost.nic"], 
                                                                    @"-alias", [vhostInfo objectForKey:@"vhost.ip"],
                                                                    nil ]; 
            
            NSTask *ifconfig =[[NSTask alloc] init];
            [ifconfig setLaunchPath:@"/sbin/ifconfig"];	
            [ifconfig setArguments:ifargs];
            [ifconfig launch]; 
            [ifconfig release]; // alias created
        }
		[vhosts release];
    }
    
}


@end
