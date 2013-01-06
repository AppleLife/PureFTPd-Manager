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

#include <Foundation/Foundation.h>
#import <Security/Security.h>
#import "AuthForAllImpl.h"
#import "AuthForAllImplCompat.h"
#import <Cocoa/Cocoa.h>

int main(int argc, const char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    OSStatus        err;
    UInt32          response;
    [NSApplication sharedApplication];
	
	
    err = Gestalt(gestaltSystemVersion, (SInt32 *) &response);
    
    if ( (err == noErr) && (response >= 0x01030) ) {
        err = SetupAuthorization();
        err = AcquireRight(kRightName);
        if (err == noErr) {
            err = ExecuteWithPrivileges(argv[1], argv[2]);
			
			NSString *username = NSUserName();
			[username writeToFile:@"/tmp/mLauncher-user" atomically:YES];
        } else if (err == errAuthorizationDenied) {
            fprintf(stderr, "errAuthorizationDenied.\n");
            return -1;
        }
    } else if (err == noErr){
        err = CompatSetupAuthorization();
		
        err = CompatAcquireRight(CompatkRightName);
        if (err == noErr) {
            err = CompatExecuteWithPrivileges(argv[1], argv[2]);
        } else if (err == errAuthorizationDenied) {
            fprintf(stderr, "errAuthorizationDenied.\n");
            return -1;
        }
    }
    
	
	    
    [pool release];
    return 0;
}