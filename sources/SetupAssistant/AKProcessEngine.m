/*
    Copyright (c) 2003, Stephane Sudre
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted
    provided that the following conditions are met:

	Redistributions of source code must retain the above copyright notice, this list of conditions
    and the following disclaimer.

	Redistributions in binary form must reproduce the above copyright notice, this list of conditions
    and the following disclaimer in the documentation and/or other materials provided with the distribution.

	Neither the name of the WhiteBox nor the names of its contributors may be used to endorse 
    or promote products derived from this software without specific prior written permission.


	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
    IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
    CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "AKProcessEngine.h"

const char * AKPEAuthentication="assistant.install";

@implementation AKProcessEngine

- (void) initPrivilege
{
    AuthorizationRights rights;
    AuthorizationFlags flags;
    OSStatus err;
    
    authorizationRef_=NULL;
    
    // We just want the user's current authorization environment,
    // so we aren't asking for any additional rights yet.

    rights.count=0;
    rights.items = NULL;
        
    flags = kAuthorizationFlagDefaults;
    
    err = AuthorizationCreate(&rights, kAuthorizationEmptyEnvironment, flags, &authorizationRef_);
}

- (AuthorizationRights) authorizationRights
{
    AuthorizationItem * item;
    AuthorizationRights rights;
    
    item=(AuthorizationItem *) calloc(1,sizeof(AuthorizationItem));
    
    item[0].name = AKPEAuthentication;
    item[0].value = NULL;
    item[0].valueLength = 0;
    item[0].flags = 0;
    
    rights.count=1;
    rights.items = item;
    
    return rights;
}


- (BOOL) isAuthorized
{
    AuthorizationRights rights;
    AuthorizationFlags flags;
    OSStatus err;
    
    rights=[self authorizationRights];
    
    flags = kAuthorizationFlagInteractionAllowed;

    // Here, since we've specified kAuthorizationFlagExtendRights and
    // have also specified kAuthorizationFlagInteractionAllowed, if the
    // user isn't currently authorized to execute tools as root 
    // (kAuthorizationRightExecute),they will be asked for their password. 

    // The err return value will indicate authorization success or failure.

    err = AuthorizationCopyRights(authorizationRef_,&rights,
                                  kAuthorizationEmptyEnvironment,
                                  flags, NULL);
    
    if (rights.count>0 && rights.items!=NULL)
    {
        free(rights.items);
    }
                                                                                              
    return ((errAuthorizationSuccess==err) ? YES : NO);
}

- (BOOL) privilegeCheck
{
    AuthorizationRights rights;
    AuthorizationFlags flags;
    OSStatus err;
    
    rights=[self authorizationRights];
    
    flags = kAuthorizationFlagInteractionAllowed 
               | kAuthorizationFlagExtendRights;

    // Here, since we've specified kAuthorizationFlagExtendRights and
    // have also specified kAuthorizationFlagInteractionAllowed, if the
    // user isn't currently authorized to execute tools as root 
    // (kAuthorizationRightExecute),they will be asked for their password. 

    // The err return value will indicate authorization success or failure.

    err = AuthorizationCopyRights(authorizationRef_,&rights,
                                  kAuthorizationEmptyEnvironment,
                                  flags, NULL);
    
    if (rights.count>0 && rights.items!=NULL)
    {
        free(rights.items);
    }
                                  
    return ((errAuthorizationSuccess==err) ? YES : NO);
}

- (void) removePrivilege
{
    AuthorizationFree(authorizationRef_,kAuthorizationFlagDestroyRights);
}

- (void) startProcess
{
    /* Overload this method */
}

- (BOOL) endProcess
{
    /* Overload this method */
    
    return YES;
}

@end
