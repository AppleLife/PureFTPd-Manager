//
//  ManagerProcessEngine.h
//  PureFTP
//
//  Created by Jean-Matthieu on Thu Feb 05 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import "AKProcessEngine.h"
#import "defines.h"
#import <Cocoa/Cocoa.h>

#include <sys/types.h>
#include <pwd.h>
#include <grp.h>

#define ATSTARTUP @"AtStartup"
#define ANONGROUP @"FtpGroup"
#define ANONHOME @"FtpHome"
#define ANONSKIP @"FtpSkip"
#define ANONUID @"FtpUID"
#define LOGNICE @"LogNiceToggle"
#define LOGSTATE @"LogToggle"
#define LOGUPDATE @"LogUpdate"
#define VHHOME @"VHHome"
#define VUGID @"VUGID"
#define VUGROUP @"VUGroupName"
#define VUHOME @"VUHome"
#define VULOGIN @"VULogin"
#define VUSKIP @"VUSkip"
#define VUUID @"VUUID"
#define RDV @"Zeroconf"

@interface ManagerProcessEngine : AKProcessEngine
{
    NSMutableDictionary *allOptions;
    NSMutableDictionary *wizardOptions;
    NSString *settingsReview;
}

-(NSMutableDictionary *) allOptions;
-(NSMutableDictionary *) wizardOptions;
-(NSString *)settingsReview;


-(BOOL) uniqGID:(int) aGID;
-(BOOL) uniqUID:(int) aUID;
-(BOOL) uniqGroup:(NSString*) aGroup;
-(BOOL) uniqUser:(NSString*) aUser;
-(BOOL) checkUID:(int) aUID forUser:(NSString *)aUser;
-(BOOL) checkGID:(int) aGID forGroup:(NSString *)aGroup;

- (void) addToStartup:(BOOL) onOff;
-(int) getXinetdPid;
-(NSMutableArray *) generateArguments;

-(NSMutableArray *) getSysGroups;
-(NSMutableArray *) getSysUsers;

-(void)createAnonymousUser;
-(void)createFTPVirtualUser;
-(void)createFTPVirtualGroup;

@end
