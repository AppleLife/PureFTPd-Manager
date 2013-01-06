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

#import "FTPUsage.h"


int mmap_fd = -1;
//static signed char dont_resolve_ip;
static struct flock lock;

void ftpwho_unlock(void) 
{
    lock.l_type = F_UNLCK;
    while (fcntl(mmap_fd, F_SETLK, &lock) < 0) {
        if (errno != EINTR) {
            return;
        }    
    }
}

void ftpwho_lock(void)
{
    lock.l_type = F_RDLCK;
    while (fcntl(mmap_fd, F_SETLKW, &lock) < 0) {
        if (errno != EINTR) {
            return;
        }    
    }    
}


static inline int checkproc(const pid_t proc)
{    
    return kill(proc, 0) == 0;
}

@implementation FTPUsage

-(id) init
{
    self = [super init];
    if (self)
    {
	usageDictionary = [[NSMutableDictionary alloc] init];
	usersDB = [[NSMutableArray alloc] init];
	
	[usageDictionary setObject:usersDB forKey:@"usersDB"];
	
	return self;
    }
    return nil;
}

-(void) dealloc
{
    [usageDictionary release];
    [usersDB release];
	[super dealloc];
}

-(void) update 
{
    
    [self clearUsersDB];
    DIR *dir;
    struct dirent *entry;
    struct stat st;
    FTPWhoEntry *scanned_entry;
    int locked;
    int delete_file;
    const char *state;
    time_t now;
    
    now = time(NULL);
    if (chdir(SCOREBOARD_PATH) != 0 ||
        (dir = opendir(".")) == NULL) {
        /*fprintf(stderr, "Unable to open the ftpwho scoreboard.\n"
                "Make sure that the [" SCOREBOARD_PATH "/] directory exists,\n"
                "Or wait until a client connects, so that it gets\n"
                "automatically created. This message doesn't mean that your\n"
                "server didn't start properly. It probably just means that\n"
                "you are running it with ftpwho for the first time.\n"); */
        return;
    }

    lock.l_whence = SEEK_SET;
    lock.l_start = (off_t) 0;
    lock.l_len = (off_t) 0;
    lock.l_pid = getpid();    
    // output_header();
    while ((entry = readdir(dir)) != NULL) {
        mmap_fd = -1;
        locked = 0;
        delete_file = 0;
        scanned_entry = NULL;
        if (strncmp(entry->d_name, SCOREBOARD_PREFIX,
                    sizeof SCOREBOARD_PREFIX - 1U) != 0) {
            goto nextone;
        }
        if ((mmap_fd = open(entry->d_name, O_RDWR | O_NOFOLLOW)) == -1) {
            goto nextone;
        }
        if (fstat(mmap_fd, &st) != 0 || !S_ISREG(st.st_mode) ||
            (st.st_mode & 0600) != 0600 || 
            st.st_size != (off_t) sizeof (FTPWhoEntry) ||
	    /*To check*/
	    st.st_uid != geteuid()) {
            goto nextone;
        }
        ftpwho_lock();
        locked++;
        if ((scanned_entry = (FTPWhoEntry *) mmap(NULL, sizeof (FTPWhoEntry),
                                                  PROT_READ, 
                                                  MAP_SHARED | MAP_FILE, 
                                                  mmap_fd, (off_t) 0)) == NULL) {
            goto nextone;
        }
        if (checkproc(scanned_entry->pid) == 0) {
            /* still in the scoreboard, but no more process */
            delete_file++;
            goto nextone;
        }        
        if (scanned_entry->state != FTPWHO_STATE_FREE) {
            unsigned long since;
            unsigned long xfer_since;
            char local_port[NI_MAXSERV];
            char local_hbuf[NI_MAXHOST];            
            char hbuf[NI_MAXHOST];
	    
            switch (scanned_entry->state) {
		case FTPWHO_STATE_IDLE :
		    state = "Idle";
		    break;
		case FTPWHO_STATE_DOWNLOAD :
		    state = " Downloading ";
		    break;
		case FTPWHO_STATE_UPLOAD :
		    state = " Uploading ";
		    break;
		default :
		    state = "Error!";
            }
            if (scanned_entry->date < now) {
                since = (unsigned long) (now - scanned_entry->date);
            } else {
                since = 0UL;
            }
            if (scanned_entry->xfer_date > (time_t) 0 &&
                scanned_entry->xfer_date < now) {
                xfer_since = (unsigned long) (now - scanned_entry->xfer_date);
            } else {
                xfer_since = 0UL;
            }
            for (;;) {
                int eai;
		
                if ((eai = getnameinfo
                     ((struct sockaddr *) &scanned_entry->addr,
                      STORAGE_LEN(scanned_entry->addr),
                      hbuf, sizeof hbuf, NULL, (size_t) 0U,
		      NI_NUMERICHOST)) == 0) {
		    //dont_resolve_ip != 0 ? NI_NUMERICHOST : 0)) == 0) {
                    break;
                }
		
		goto nextone;
            }
            for (;;) {
                int eai;
                
                if ((eai = getnameinfo
                     ((struct sockaddr *) &scanned_entry->local_addr,
                      STORAGE_LEN(scanned_entry->addr),
                      local_hbuf, sizeof local_hbuf,
                      local_port, sizeof local_port,
		      (NI_NUMERICHOST | NI_NUMERICSERV) )) == 0) {
                      /*dont_resolve_ip != 0 ? (NI_NUMERICHOST | NI_NUMERICSERV) :
                      NI_NUMERICSERV)) == 0) {*/
                    break;
                }
		goto nextone;
            }
	    
	    [self fillDictionaryFor:[NSString stringWithCString: scanned_entry->account]
			 PID: scanned_entry->pid
		       since: since
		  xfer_since: xfer_since
		       state:[NSString stringWithCString:state]
		    filename:[NSString stringWithCString:scanned_entry->filename]
			hbuf:[NSString stringWithCString:hbuf]
		  local_hbuf:[NSString stringWithCString:local_hbuf]
		  local_port:[NSString stringWithCString: local_port]
		   restartat:(scanned_entry->restartat <= scanned_entry->download_current_size) ? 
                              scanned_entry->restartat : (off_t) 0
		  total_size: (scanned_entry->state == FTPWHO_STATE_DOWNLOAD) ?
			       scanned_entry->download_total_size : (off_t) 0
		current_size: (scanned_entry->state == FTPWHO_STATE_DOWNLOAD ||
			       scanned_entry->state == FTPWHO_STATE_UPLOAD) ?
                               scanned_entry->download_current_size : (off_t) 0];
        }
nextone:
	    if (locked != 0 && mmap_fd != -1) {
		ftpwho_unlock();
	    }
        if (scanned_entry != NULL) {
            (void) munmap((void *) scanned_entry, sizeof (FTPWhoEntry));
        }
        if (mmap_fd != -1) {
            close(mmap_fd);
        }
        if (delete_file != 0) {
            unlink(entry->d_name);
        }
    }
    
}


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
				  current_size:(const off_t) current_size
{
    NSMutableDictionary *tmpDictionary = [[NSMutableDictionary alloc] init];
    
    NSString *aPid = [NSString stringWithFormat:@"%lu", pid];
    [tmpDictionary setObject:aPid forKey:@"pid"];
    
    [tmpDictionary setObject:account forKey:@"account"];

    NSString *aSince = [NSString stringWithFormat:@"%lu", since]; 
    [tmpDictionary setObject:aSince forKey:@"time"];

    [tmpDictionary setObject:state forKey:@"state"];
    [tmpDictionary setObject:filename forKey:@"file"];
    [tmpDictionary setObject:hbuf forKey:@"host"];
    [tmpDictionary setObject:local_hbuf forKey:@"localhost"];
    [tmpDictionary setObject:local_port forKey:@"localport"];
    
    if (current_size > (off_t) 0) {
        unsigned long bandwidth;
        long double pct;
        int pcti;        
        
        if (xfer_since > 0UL && current_size > restartat) {
            bandwidth = (unsigned long) ((current_size - restartat) / xfer_since);
        } else {
            bandwidth = 0UL;
        }        
        if ((long double) total_size > 0.0L) {
            pct = ((long double) current_size * 100.0L) / (long double) total_size;
            pcti = (int) (pct + 0.5L);
            if (pcti > 100) {
                pcti = 100;           /* should never happen */
            }
	    
	    NSString *aRestart = [NSString stringWithFormat:@"%llu", restartat]; 
	    [tmpDictionary setObject:aRestart forKey:@"resume"];
	    NSString *acsize = [NSString stringWithFormat:@"%llu", current_size]; 
	    [tmpDictionary setObject:acsize forKey:@"current_size"];
	    NSString *atsize = [NSString stringWithFormat:@"%llu", total_size]; 
	    [tmpDictionary setObject:atsize forKey:@"total_size"];
	    
	    NSString *apcti = [NSString stringWithFormat:@"%d", pcti]; 
	    [tmpDictionary setObject:apcti forKey:@"percentage"];
	    NSString *abw = [NSString stringWithFormat:@"%lu", bandwidth]; 
	    [tmpDictionary setObject:abw forKey:@"bandwidth"];
	    
	} else {
	    NSString *aRestart = [NSString stringWithFormat:@"%llu", restartat]; 
	    [tmpDictionary setObject:aRestart forKey:@"resume"];
	    NSString *acsize = [NSString stringWithFormat:@"%llu", current_size]; 
	    [tmpDictionary setObject:acsize forKey:@"current_size"];
	    NSString *abw = [NSString stringWithFormat:@"%lu", bandwidth]; 
	    [tmpDictionary setObject:abw forKey:@"bandwidth"];
	}
    } else { 
	NSString *emptyOne = @"";
	[tmpDictionary setObject:emptyOne forKey:@"resume"];
	[tmpDictionary setObject:emptyOne forKey:@"current_size"];
	[tmpDictionary setObject:emptyOne forKey:@"total_size"];
	[tmpDictionary setObject:emptyOne forKey:@"percentage"];
	[tmpDictionary setObject:emptyOne forKey:@"bandwidth"];
    }
    
    [usersDB addObject:tmpDictionary];
    [tmpDictionary release];
}

-(void) clearUsersDB
{
    [usersDB removeAllObjects];
}

-(NSMutableArray *) usersDB
{
    return usersDB;
}

-(NSMutableDictionary *) usageDictionary
{
    return usageDictionary;
}


@end
