/*
 *  AuthForAllImplCompat.h
 *  PureFTP
 *
 *  Created by Jean-Matthieu on 27/09/2004.
 *  Copyright 2004 __MyCompanyName__. All rights reserved.
 *
 */


#ifndef _AUTHFORALLIMPLCOMPAT_H_
#define _AUTHFORALLIMPLCOMPAT_H_

#include <Carbon/Carbon.h>

extern const char CompatkRightName[];

extern OSStatus CompatExecuteWithPrivileges(const char * path, const char* language);
extern OSStatus CompatAcquireRight(const char *rightName);
extern OSStatus CompatSetupAuthorization(void);


#endif
