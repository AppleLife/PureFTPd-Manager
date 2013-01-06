//
//  FTPUsage.h
//  PureFTP
//
//  Created by Jean-Matthieu on Sun Dec 07 2003.
//  Copyright (c) 2003 __MyCompanyName__. All rights reserved.
//

#define SCOREBOARD_PATH "/var/run/pure-ftpd"
#define SCOREBOARD_PREFIX "client-"

#import <Foundation/Foundation.h>

#include <sys/types.h>
#include <sys/socket.h>
#include <sys/file.h>
#include <sys/dir.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <netdb.h>
#include <time.h>
#include <unistd.h>
#include <tcpd.h>
#include <netinet/in.h>

#define STORAGE_FAMILY(X) ((X).ss_family)
#define STORAGE_LEN(X) (STORAGE_FAMILY(X) == AF_INET ? sizeof(struct sockaddr_in) : sizeof(struct sockaddr_in6))


typedef enum {
    FTPWHO_STATE_FREE = 0,                    /* must be first (0) */
    FTPWHO_STATE_IDLE, FTPWHO_STATE_DOWNLOAD, FTPWHO_STATE_UPLOAD
} FTPWhoEntryState;


void ftpwho_lock(void);
void ftpwho_unlock(void);

void readmemory(void);

typedef struct FTPWhoEntry_ {
    FTPWhoEntryState state;        
    pid_t pid;
    struct sockaddr_storage addr;
    struct sockaddr_storage local_addr;    
    time_t date;
    time_t xfer_date;
    volatile off_t restartat;
    volatile off_t download_total_size;
    volatile off_t download_current_size;    
    char account[32U + 1U];
    char filename[1024];
} FTPWhoEntry;

@interface FTPUsage : NSObject {
    NSMutableDictionary *usageDictionary;
    NSMutableArray *usersDB;
    
    
}
/* Update usageDirectory by reading pure-ftpd memory mapped files */
-(void) update;

/* Fills in the usageDirectory with relevent data */
-(void) fillDictionaryFor:(NSString *) account
				    PID:(const pid_t) pid
				  since:(const unsigned long) since
			     xfer_since:(const unsigned long) xfer_since
				  state:(NSString *) state
			       filename:(NSString *) filename
				   hbuf:(NSString *) hbuf
			     local_hbuf:(NSString *) local_hbuf
			     local_port:(NSString *) local_port
			      restartat:(const off_t) restartat                              
			     total_size:(const off_t) total_size
			   current_size:(const off_t) current_size;

/* Wipes out the usersDB Array */
-(void) clearUsersDB;

/* Returns usersDB Array */
-(NSMutableArray *) usersDB;

/* Returns the usageDictionary */
-(NSMutableDictionary *) usageDictionary;

@end
