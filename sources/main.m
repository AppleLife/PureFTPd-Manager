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



#import <Cocoa/Cocoa.h>
#import <Security/Security.h>
#include <unistd.h>

//#import "AuthForAllImpl.h"
//#import "AuthForAllImplCompat.h"
//#include <assert.h>
//#include <Carbon/Carbon.h>
//#include <sys/stat.h>
//#include <fcntl.h>
//#include <sys/types.h>
//#include <sys/param.h>
//#include <stdio.h>



void CheckPermissions(void)
{
	NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	NSFileManager *manager = [NSFileManager defaultManager];
	NSString *executable = [[NSBundle mainBundle] executablePath];
	const char *path = [manager fileSystemRepresentationWithPath:executable];

	AuthorizationRef auth;
	OSStatus err;
	
	NSString *username = NSUserName();
	NSString *userHome = NSHomeDirectory();
	NSString *userProperties = [NSString stringWithFormat:@"%@/Library/Preferences/org.pureftpd.macosx.plist", userHome];
	//NSLog(@"prop:%@",userProperties);
	
	NSFileManager *fm = [NSFileManager defaultManager];
	
	// try to switch to root user.
	seteuid(0);
	setuid(0);
	if (geteuid() != 0)
		{
		// Must be relaunched as root, then this instance must be quit
		// launch as root
		//[[NSUserDefaults standardUserDefaults] synchronize];
	
		//[fm removeFileAtPath:userProperties handler:nil];
		
		if (path)
		{
			
			err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagInteractionAllowed, &auth);
			if (err == errAuthorizationSuccess)
				err = AuthorizationExecuteWithPrivileges(auth, path, kAuthorizationFlagDefaults, NULL, NULL);
		}
		[pool release];
		exit(0);
	}
	
	
	[username writeToFile:@"/tmp/PureFTPdManagerUser" atomically:YES];
	
	// switch to root
	seteuid(0);
	setuid(0);
	
	NSString *rootProperties = @"/private/var/root/Library/Preferences/org.pureftpd.macosx.plist";
	
	if ([fm fileExistsAtPath:rootProperties])
	{
		[fm removeFileAtPath:userProperties handler:nil];
			
		[fm copyPath:rootProperties toPath:userProperties handler:nil];
		NSDictionary *attr=[NSDictionary dictionaryWithObjectsAndKeys:
							username, NSFileOwnerAccountName, nil];
		[fm changeFileAttributes:attr atPath:userProperties];
	}
		
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	// Switch to front
	[pool release];
	//
}


int main(int argc, const char *argv[])
{
	CheckPermissions();
	return NSApplicationMain(argc , (const char **)argv);
}