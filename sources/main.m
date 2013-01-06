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
//#import "AuthForAllImpl.h"
//#import "AuthForAllImplCompat.h"

//#include <assert.h>
#include <Carbon/Carbon.h>
#include <Security/Security.h>

#include <CoreFoundation/CoreFoundation.h>
#include <unistd.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <sys/types.h>
#include <sys/param.h>
#include <stdio.h>

static bool pathForTool(CFStringRef toolName, char path[MAXPATHLEN])
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
}

int main(int argc, const char *argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    char path[MAXPATHLEN], launcher[MAXPATHLEN];
    
    if (!pathForTool(CFSTR("../MacOS/Launcher"), launcher))
    {
        fprintf(stderr, "PureFTPd Manager Authentificator could not be found.\n");
        return -1;
    }
    
    
    if (!pathForTool(CFSTR("../MacOS/PureFTPd Manager"), path))
    {
        fprintf(stderr, "PureFTPd Manager could not be found.\n");
        return -1;
    }
    
    uid_t aUID = geteuid();
    
    
    if (aUID !=0) {
        NSTask *task = [[NSTask alloc] init];
        NSArray *languages = [NSArray arrayWithObjects:@"en", @"fr", nil];
        NSArray *userPrefLanguage = [NSBundle preferredLocalizationsFromArray:languages forPreferences:nil];
        NSString *appleLanguage = [NSString stringWithFormat:@"(\"%@\")", [userPrefLanguage objectAtIndex:0]]; 
        [task setLaunchPath:[NSString stringWithFormat:@"%s", launcher]];
        [task setArguments:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%s", path], appleLanguage, nil]];
        [task launch];
        [task release];
        [pool release];
        return 0;
    } else {
        
        setuid(0);
        return NSApplicationMain(argc , (const char **)argv);
    }
    
    [pool release];
    return 0;
}