/*
    File:       AuthForAllImpl.c

    Contains:   Implementation for sample code purposes.

    Written by: DTS

    Copyright:  Copyright (c) 2003 by Apple Computer, Inc., All Rights Reserved.

    Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
                ("Apple") in consideration of your agreement to the following terms, and your
                use, installation, modification or redistribution of this Apple software
                constitutes acceptance of these terms.  If you do not agree with these terms,
                please do not use, install, modify or redistribute this Apple software.

                In consideration of your agreement to abide by the following terms, and subject
                to these terms, Apple grants you a personal, non-exclusive license, under Apple's
                copyrights in this original Apple software (the "Apple Software"), to use,
                reproduce, modify and redistribute the Apple Software, with or without
                modifications, in source and/or binary forms; provided that if you redistribute
                the Apple Software in its entirety and without modifications, you must retain
                this notice and the following text and disclaimers in all such redistributions of
                the Apple Software.  Neither the name, trademarks, service marks or logos of
                Apple Computer, Inc. may be used to endorse or promote products derived from the
                Apple Software without specific prior written permission from Apple.  Except as
                expressly stated in this notice, no other rights or licenses, express or implied,
                are granted by Apple herein, including but not limited to any patent rights that
                may be infringed by your derivative works or by other works in which the Apple
                Software may be incorporated.

                The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
                WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
                WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
                PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
                COMBINATION WITH YOUR PRODUCTS.

                IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
                CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
                GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
                ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
                OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
                (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
                ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

    Change History (most recent first):

$Log$

*/

/////////////////////////////////////////////////////////////////

// System interfaces

#import <assert.h>
#import <stdio.h>
#import <Carbon/Carbon.h>
#import <Security/Security.h>
#import <CoreFoundation/CoreFoundation.h>
#import <Foundation/Foundation.h>

// Our prototypes

#include "AuthForAllImpl.h"

/////////////////////////////////////////////////////////////////

static AuthorizationRef gAuthorization = NULL;
    // Our connection to Authorization Services.

//const char kRightName[] = "org.pureftpd.macosx";
const char kRightName[] = "system.privilege.admin";

extern OSStatus ExecuteWithPrivileges(const char * path, const char* language)
// This routine executes a binary with privileges
{
    OSStatus err;
    char *args[] = {"-AppleLanguages", (char *)language, NULL}; 
    static const AuthorizationFlags  kFlags =  kAuthorizationFlagDefaults;
	
    err = AuthorizationExecuteWithPrivileges(gAuthorization, path, kFlags, args, NULL);
    
    AuthorizationFree(gAuthorization,kAuthorizationFlagDestroyRights);

    return err;
}

extern OSStatus AcquireRight(const char *rightName)
    // This routine calls Authorization Services to acquire 
    // the specified right.
{
    OSStatus                         err;
    static const AuthorizationFlags  kFlags = kAuthorizationFlagDefaults |
		kAuthorizationFlagPreAuthorize |
        kAuthorizationFlagInteractionAllowed | 
        kAuthorizationFlagExtendRights; 
    AuthorizationItem   kActionRight = { rightName, 0, 0, 0 };
    AuthorizationRights kRights      = { 1, &kActionRight };

    assert(gAuthorization != NULL);

    // Request the application-specific right.

    err = AuthorizationCopyRights(
        gAuthorization,         // authorization
        &kRights,               // rights
        NULL,                   // environment
        kFlags,                 // flags
        NULL                    // authorizedRights
    );

    return err;
}

static OSStatus AuthorizationRightSetWithWorkaround(
    AuthorizationRef    authRef,
    const char *        rightName,
    CFTypeRef           rightDefinition,
    CFStringRef         descriptionKey,
    CFBundleRef         bundle,
    CFStringRef         localeTableName
)
    // The AuthorizationRightSet routine has a bug where it 
    // releases the bundle parameter that you pass in (or the 
    // main bundle if you pass NULL).  If you do pass NULL and 
    // call AuthorizationRightSet multiple times, eventually the 
    // main bundle's reference count will hit zero and you crash. 
    //
    // This routine works around the bug by doing an extra retain 
    // on the bundle.  It should also work correctly when the bug 
    // is fixed.
    //
    // Note that this technique is not thread safe, so it's 
    // probably a good idea to restrict your use of it to 
    // application startup time, where the threading environment 
    // is very simple.
{
    OSStatus        err;
    CFBundleRef     clientBundle;
    CFIndex         originalRetainCount;

    // Get the effective bundle.

    if (bundle == NULL) {
        clientBundle = CFBundleGetMainBundle();
    } else {
        clientBundle = bundle;
    }
    assert(clientBundle != NULL);

    // Remember the original retain count and retain it.  We force 
    // a retain because if the retain count was 1 and the bug still 
    // exists, the next call might decrement the count to 0, which 
    // would free the object.

    originalRetainCount = CFGetRetainCount(clientBundle);
    CFRetain(clientBundle);
	
    err = AuthorizationRightSet(
        authRef, 
        rightName, 
        rightDefinition, 
        descriptionKey, 
        clientBundle, 
        localeTableName
    );    
	
	// If the retain count is now magically back to its original value, 
    // we've encountered the bug and we print a message.  Otherwise the 
    // bug must've been fixed and we just balance our retain with a release.

    if ( CFGetRetainCount(clientBundle) == originalRetainCount ) {
        /*fprintf(
            stderr, 
            "AuthForAll: Working around <rdar://problems/3446163>\n"
        );*/
    } else {
        CFRelease(clientBundle);
    }

    return err;
}

static OSStatus SetupRight(
    AuthorizationRef    authRef, 
    const char *        rightName, 
    CFTypeRef         rightRule, 
    CFStringRef         rightPrompt
)
    // Checks whether a right exists in the authorization database 
    // and, if not, creates the right and sets up its initial value.
{
    OSStatus err;

    // Check whether our right is already defined.
    err = AuthorizationRightGet(rightName, NULL);
       
    if (err == noErr) {
	
        // A right already exists, either set up in advance by 
        // the system administrator or because this is the second 
        // time we've run.  Either way, there's nothing more for 
        // us to do.

    } else if (err == errAuthorizationDenied){
        // The right is not already defined.  Let's create a 
        // right definition based on the rule specified by the 
        // caller (in the rightRule parameter).  This might be 
        // kAuthorizationRuleClassAllow (which allows anyone to 
        // acquire the right) or kAuthorizationRuleAuthenticateAsAdmin 
        // (which requires the user to authenticate as an admin user) 
        // or some other value from "AuthorizationDB.h".  The system 
        // administrator can modify this right as they see fit.
       
		
        err = AuthorizationRightSetWithWorkaround(
            authRef,                // authRef
            rightName,              // rightName
            rightRule,        // rightDefinition
            NULL,            // descriptionKey
            NULL,                   // bundle, NULL indicates main bundle
            NULL                    // localeTableName, 
        );                          // NULL indicates "Localizable.strings"

        // The ability to add a right is, itself, governed by a right. 
        // If we can't get that right, we'll get an error from the above 
        // routine.  We don't want that error stopping the application 
        // from launching, so we swallow the error.

        if (err != noErr) {
            #if ! defined(NDEBUG)
                fprintf(stderr, "Could not create default right (%ld)\n", err);
            #endif
            err = noErr;
        }
		
	}
    
    return err;
}

extern OSStatus SetupAuthorization(void)
    // Called as the application starts up.  Creates a connection 
    // to Authorization Services and then makes sure that our 
    // right (kActionRightName) is defined.
{
    OSStatus err;

    // Connect to Authorization Services.

    err = AuthorizationCreate(NULL, kAuthorizationEmptyEnvironment, kAuthorizationFlagDefaults, &gAuthorization);
	/*NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"allow-root", 
																	@"user", @"class",
																	@"admin", @"group", 
																	[NSNumber numberWithBool:NO], @"shared",
																	[NSNumber numberWithInt:0], @"timeout", nil];*/

    if (err == noErr) {
        err = SetupRight(
            gAuthorization, 
            kRightName, 
			CFSTR(kAuthorizationRuleAuthenticateAsAdmin),
            CFSTR("")
        );
    }
   
    return err;
}
