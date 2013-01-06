/*
    File:       AuthForAllCompat.c

    Contains:   Implementation with scary compatibility code.

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

#include <assert.h>
#include <stdio.h>
#include <Carbon/Carbon.h>
#include <Security/Security.h>

// Our prototypes

#include "AuthForAllImplCompat.h"

/////////////////////////////////////////////////////////////////

// If we must run on older systems, we have to jump through some hoops, 
// both to access the "AuthorizationDB.h" functions if they're present 
// and to apply a heuristic if they're not.

// If you set TEST_OLD_CODE_ON_TEN_THREE to 1, you can test the pre-10.3 
// code on 10.3 by copying a pre-10.3 "/etc/authorization to the root 
// directory (that is, "/authorization").

#define TEST_OLD_CODE_ON_TEN_THREE 0

/////////////////////////////////////////////////////////////////
#pragma mark ***** Framework glue

// Because we need to load on old systems (specifically 10.1, where weak linking 
// isn't available), we have to load the new Authorization Services routines 
// manually.  This is the glue to do that.

static OSStatus LoadFrameworkBundle(CFStringRef framework, CFBundleRef *bundlePtr)
    // This routine finds a the named framework and creates a CFBundle 
    // object for it.  It looks for the framework in the frameworks folder, 
    // as defined by the Folder Manager.  Currently this is 
    // "/System/Library/Frameworks", but we recommend that you avoid hard coded 
    // paths to ensure future compatibility.
    //
    // You might think that you could use CFBundleGetBundleWithIdentifier but 
    // that only finds bundles that are already loaded into your context. 
    // That would work in the case of the System framework but it wouldn't 
    // work if you're using some other, less-obvious, framework.
{
    OSStatus    err;
    FSRef       frameworksFolderRef;
    CFURLRef    baseURL;
    CFURLRef    bundleURL;
    
    assert( bundlePtr != NULL);
    assert(*bundlePtr == NULL);
    
    baseURL = NULL;
    bundleURL = NULL;
    
    // Find the frameworks folder and create a URL for it.
    
    err = FSFindFolder(kOnAppropriateDisk, kFrameworksFolderType, true, &frameworksFolderRef);
    if (err == noErr) {
        baseURL = CFURLCreateFromFSRef(kCFAllocatorSystemDefault, &frameworksFolderRef);
        if (baseURL == NULL) {
            err = coreFoundationUnknownErr;
        }
    }
    
    // Append the name of the framework to the URL.
    
    if (err == noErr) {
        bundleURL = CFURLCreateCopyAppendingPathComponent(kCFAllocatorSystemDefault, baseURL, framework, false);
        if (bundleURL == NULL) {
            err = coreFoundationUnknownErr;
        }
    }
    
    // Create a bundle based on that URL and load the bundle into memory.
    // We never unload the bundle, which is reasonable in this case because 
    // the sample assumes that you'll be calling functions from this 
    // framework throughout the life of your application.
    
    if (err == noErr) {
        *bundlePtr = CFBundleCreate(kCFAllocatorSystemDefault, bundleURL);
        if (*bundlePtr == NULL) {
            err = coreFoundationUnknownErr;
        }
    }
    if (err == noErr) {
        if ( ! CFBundleLoadExecutable( *bundlePtr ) ) {
            err = coreFoundationUnknownErr;
        }
    }

    // Clean up.
    
    if (err != noErr && *bundlePtr != NULL) {
        CFRelease(*bundlePtr);
        *bundlePtr = NULL;
    }
    if (bundleURL != NULL) {
        CFRelease(bundleURL);
    }   
    if (baseURL != NULL) {
        CFRelease(baseURL);
    }   
    
    return err;
}

// Some globals used by the Authorization DB glue.

static CFBundleRef gSecurityFrameworkBundle;
static OSStatus (*gAuthorizationRightGetProcPtr)(const char *, CFDictionaryRef *);
static OSStatus (*gAuthorizationRightSetProcPtr)(
    AuthorizationRef,
    const char *,
    CFTypeRef,
    CFStringRef,
    CFBundleRef,
    CFStringRef
);

static OSStatus InitAuthorizationDBGlue(void)
    // Initialises the Authorization DB glue.  An error implies that 
    // Authorization DB is not present.
{
    OSStatus err;

    err = noErr;
    if (gSecurityFrameworkBundle == NULL) {
        err = LoadFrameworkBundle(CFSTR("Security.framework"), &gSecurityFrameworkBundle);
    }
    if (err == noErr) {
        gAuthorizationRightGetProcPtr = CFBundleGetFunctionPointerForName(
            gSecurityFrameworkBundle, 
            CFSTR("AuthorizationRightGet")
        );
        gAuthorizationRightSetProcPtr = CFBundleGetFunctionPointerForName(
            gSecurityFrameworkBundle, 
            CFSTR("AuthorizationRightSet")
        );
        if ( (gAuthorizationRightGetProcPtr == NULL) || (gAuthorizationRightSetProcPtr == NULL) ) {
            err = unimpErr;
        }
    }
    return err;
}

static OSStatus AuthorizationRightGetGlue(
    const char *rightName,
    CFDictionaryRef *rightDefinition
)
    // Glue for AuthorizationRightGet.
{
    OSStatus err;

    if (gAuthorizationRightGetProcPtr == NULL) {
        err = unimpErr;
    } else {
        err = gAuthorizationRightGetProcPtr(rightName, rightDefinition);
    }
    return err;
}

static OSStatus AuthorizationRightSetGlue(
    AuthorizationRef authRef,
    const char *rightName,
    CFTypeRef rightDefinition,
    CFStringRef descriptionKey,
    CFBundleRef bundle,
    CFStringRef localeTableName
)
    // Glue for AuthorizationRightSet.
{
    OSStatus err;

    if (gAuthorizationRightSetProcPtr == NULL) {
        err = unimpErr;
    } else {
        err = gAuthorizationRightSetProcPtr(
            authRef, 
            rightName, 
            rightDefinition, 
            descriptionKey, 
            bundle, 
            localeTableName
        );
    }
    return err;
}

/////////////////////////////////////////////////////////////////
#pragma mark ***** Compatibility Implementation

static AuthorizationRef gAuthorization = NULL;
    // Our connection to Authorization Services.

//const char CompatkRightName[] = "org.pureftpd.macosx";
const char CompatkRightName[] = "system.privilege.admin";


extern OSStatus CompatExecuteWithPrivileges(const char * path, const char* language)
// This routine executes a binary with privileges
{
    OSStatus err;
    char *args[] = {"-AppleLanguages", (char*)language, NULL};
    static const AuthorizationFlags  kFlags = kAuthorizationFlagDefaults; 
    err = AuthorizationExecuteWithPrivileges(gAuthorization, path, kFlags, args, NULL);
    
       
    AuthorizationFree(gAuthorization,kAuthorizationFlagDestroyRights);
    
    return err;
}


extern OSStatus CompatAcquireRight(const char *rightName)
    // This routine calls Authorization Services to acquire 
    // the specified right.
{
    OSStatus                         err;
    static const AuthorizationFlags  kFlags = kAuthorizationFlagDefaults | 
        kAuthorizationFlagExtendRights |
        kAuthorizationFlagInteractionAllowed | 
        kAuthorizationFlagPreAuthorize; 
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

extern pascal OSStatus CFQPropertyListCreateFromXMLCFURL(CFURLRef xmlFile, CFPropertyListMutabilityOptions options, CFPropertyListRef *result)
    // Creates a property list based on the XML in the file.
    //
    // xmlFile must not be NULL
    // result must not be NULL
    // *result must be NULL
    // on success, *result will be a valid property list
    // on error, *result will be NULL
{
    OSStatus  err;
    CFDataRef xmlData;
    
    assert(xmlFile != NULL);
    assert( result != NULL);
    assert(*result == NULL);

    xmlData = NULL;

    err = noErr;
    if ( ! CFURLCreateDataAndPropertiesFromResource(NULL, xmlFile, &xmlData, NULL, NULL, &err) && (err == noErr) ) {
        err = coreFoundationUnknownErr;
    }
    
    if (err == noErr) {
        *result = CFPropertyListCreateFromXMLData(NULL, xmlData, options, NULL);
        if (*result == NULL) {
            err = coreFoundationUnknownErr;
        }
    }

    if (xmlData != NULL) {
        CFRelease(xmlData);
    }

    assert( (err == noErr) == (*result != NULL) );
    
    return err;
}

/*static OSStatus DoesNonDefaultAuthorizationRuleExist(
    const char *rightName,
    Boolean *resultPtr
)
    // Returns true if a specific authorization rule (that is, not the 
    // default rule) exists for rightName.  This allows you to determine 
    // whether the user has added a specific rule for a right and, if not,
    // use some default other than the default rule in "/etc/authorization".
    //
    // This code should only be used on Mac OS X 10.2.x and earlier.  
    // On Mac OS X 10.3 and later, you should use the routines in
    // "AuthorizationDB.h" to achieve the same goals in a supported fashion.
    // 
    // Accessing "/etc/authorization" in the way demonstrated by this routine 
    // is not supported on newer systems.  The only reasons I can get away 
    // with this code is that I know it only needs to run on Mac OS X 10.0 
    // through 10.2.x, and the location and format of the authorization 
    // database is not going to change on those systems.
{
    OSStatus        err;
    Boolean         result;
    Boolean         done;
    CFURLRef        url;
    CFDictionaryRef authDict;
    CFStringRef     thisRight;
    CFIndex         index;
    UInt32          response;

    assert(rightName != NULL);
    assert(resultPtr != NULL);

    result       = false;
    thisRight    = NULL;
    authDict     = NULL;
    url          = NULL;
    
    err = noErr;

    // You shouldn't be runningthis code on 10.3 or later.  See 
    // above for an explanation of why not and what you should be doing.

    err = Gestalt(gestaltSystemVersion, (SInt32 *) &response);
    if ( (err == noErr) && (response >= 0x01030) ) {
        #if ! TEST_OLD_CODE_ON_TEN_THREE
            err = paramErr;
        #endif
    }

    // Read "/etc/authorization".  Note the hard-code path name.  Bad bad bad.
    // This is one of the reasons why this code is only supported on old systems.

    if (err == noErr) {
        #if TEST_OLD_CODE_ON_TEN_THREE
            url = CFURLCreateWithString(NULL, CFSTR("file:///authorization"), NULL);
        #else
            url = CFURLCreateWithString(NULL, CFSTR("file:///etc/authorization"), NULL);
        #endif
        if (url == NULL) {
            err = coreFoundationUnknownErr;
        }
    }
    if (err == noErr) {
        err = CFQPropertyListCreateFromXMLCFURL(url, kCFPropertyListImmutable, (CFPropertyListRef *) &authDict);
    }
    if ( (err == noErr) && ( CFGetTypeID(authDict) != CFDictionaryGetTypeID() ) ) {
        err = paramErr;
    }

    // Create a CFString of the rightName and see whether that string is 
    // a key in the dictionary.  If so, the right is present.  If not, 
    // look for a substring match by removing the last dot-delimited component 
    // from thisRight and trying again.
    //
    // IMPORTANT:
    // This algoritm relies on the format of "/etc/authorization".  This format 
    // was unchanged between 10.0 and 10.2.x, but has changed in 10.3.  Thus, 
    // the various checks to prevent this code running on 10.3.

    if (err == noErr) {
        thisRight = CFStringCreateWithCString(NULL, rightName, kCFStringEncodingUTF8);
        if (thisRight == NULL) {
            err = coreFoundationUnknownErr;
        }
    }
    if (err == noErr) {
        done = false;
        do {
            // CFShow(thisRight);
            if ( CFDictionaryContainsKey(authDict, thisRight) ) {
                // We have a match, return true.
                result = true;
                done   = true;
            } else {
                // Starting with the last character in the string.
                
                index = CFStringGetLength(thisRight) - 1;
                
                // Skip back over a trailing dot if present.
                
                if ( (index >= 0) && (CFStringGetCharacterAtIndex(thisRight, index) == '.') ) {
                    index -= 1;
                }

                // Skip back over any trailing non-dots.
                
                while ( (index >= 0) && (CFStringGetCharacterAtIndex(thisRight, index) != '.') ) {
                    // fprintf(stderr, "%c\n", CFStringGetCharacterAtIndex(thisRight, index));
                    index -= 1;
                }
                
                // If we've run out of characters, we're done.  Note that 
                // the test is (index > 0) because if the previous loop 
                // terminated because it found a dot, then the character 
                // at index is a dot, and a right containing just a dot makes 
                // no sense.
                
                if (index > 0) {
                    CFStringRef tmp;
                    
                    tmp = CFStringCreateWithSubstring(NULL, thisRight, CFRangeMake(0, index + 1));
                    if (tmp == NULL) {
                        err = coreFoundationUnknownErr;
                    }
                    if (err == noErr) {
                        CFRelease(thisRight);
                        thisRight = tmp;
                    }
                } else {
                    done = true;
                }
            }
        } while ( (err == noErr) && ! done);
    }
    
    // Clean up.

    if (url != NULL) {
        CFRelease(url);
    }
    if (authDict != NULL) {
        CFRelease(authDict);
    }
    if (thisRight != NULL) {
        CFRelease(thisRight);
    }
    *resultPtr = result;
    
    return err;
}*/

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

    // Call through to Authorization Services.

    err = AuthorizationRightSetGlue(
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
        fprintf(
            stderr, 
            "AuthForAll: Working around <rdar://problems/3446163>\n"
        );
    } else {
        CFRelease(clientBundle);
    }

    return err;
}

static OSStatus SetupRight(
    AuthorizationRef    authRef, 
    const char *        rightName, 
    CFStringRef         rightRule, 
    CFStringRef         rightPrompt
)
    // Checks whether a right exists in the authorization database 
    // and, if not, creates the right and sets up its initial value.
{
    OSStatus err;

    // Check whether our right is already defined.

    err = AuthorizationRightGetGlue(rightName, NULL);
    if (err == noErr) {

        // A right already exists, either set up in advance by 
        // the system administrator or because this is the second 
        // time we've run.  Either way, there's nothing more for 
        // us to do.

    } else if (err == errAuthorizationDenied) {

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
            rightRule,              // rightDefinition
            rightPrompt,            // descriptionKey
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

extern OSStatus CompatSetupAuthorization(void)
    // Called as the application starts up.  Creates a connection 
    // to Authorization Services and then makes sure that our 
    // right (kActionRightName) is defined.
{
    OSStatus    err;
    #if TEST_OLD_CODE_ON_TEN_THREE
        static const Boolean kUseAuthorizationDB = false;
    #else
        static const Boolean kUseAuthorizationDB = true;
    #endif

    // Connect to Authorization Services.

    err = AuthorizationCreate(NULL, NULL, 0, &gAuthorization);
    if (err == noErr) {

        if ( (InitAuthorizationDBGlue() == noErr) && kUseAuthorizationDB ) {
            // We have the "AuthorizationDB.h" functions.  Let's do  
            // it the modern, supported way.

            if (err == noErr) {
                err = SetupRight(
                                 gAuthorization, 
                                 CompatkRightName, 
                                 CFSTR(kAuthorizationRuleAuthenticateAsAdmin),
                                 CFSTR("")
                                 );
            }
        } else {
            // For the "CompatKRight" right we want to default to requiring an admin 
            // password.  That's the default for unspecified rights, so we 
            // don't need to do anything.
        }
    }

    return err;
}
