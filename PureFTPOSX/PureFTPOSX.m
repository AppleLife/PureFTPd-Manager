//
//  PureFTPOSX.m
//  PureFTP
//
//  Created by Jean-Matthieu Schaffhauser on 09/03/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "defines.h"
#import "PureFTPD.h"

void usage(void){
    char *license = "\nThis program is free software; you can redistribute it and/or modify\n\
it under the terms of the GNU General Public License version 2 as published\n\
by the Free Software Foundation.\n\n\
This program is distributed in the hope that it will be useful,\n\
but WITHOUT ANY WARRANTY; without even the implied warranty of\n\
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the\n\
GNU General Public License for more details.\n\n\
You should have received a copy of the GNU General Public License\nalong with this program; if not, write to the Free Software\n\
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA\n02111-1307, USA.";
    char *usage="Usage : PureFTPOSX [start|stop|restart|status|help]";
    
    printf("%s\n%s\n", usage, license);
}


int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    
	if (getuid(0) != 0){
		fprintf(stderr, "You must root to run this program.\n");
		return;
	}
	
    if (argc != 2)
        usage();
    else{
		PureFTPD *server = [[PureFTPD alloc] init];
		
        if (strcmp(argv[1], "start") == 0) {
            if ([server isServerRunning])
			{
				fprintf(stderr, "pure-ftpd is already running.\n");
				return;
			} else {
				fprintf(stderr, "Starting pure-ftpd ...\n");
				[server startServer];
				fprintf(stderr, "Done.\n");
			}
        } else if (strcmp(argv[1], "stop") == 0) {
            if (![server isServerRunning])
			{
				fprintf(stderr, "pure-ftpd is not running.\n");
				return;
			} else {
				fprintf(stderr, "Stopping pure-ftpd ...\n");
				[server stopServer];
				fprintf(stderr, "Done.\n");
			}
		} else if (strcmp(argv[1], "restart") == 0) {
			if ([server isServerRunning])
			{
				fprintf(stderr, "Restarting pure-ftpd ...\n");
				[server stopServer];
				[server startServer];
			} else {
				fprintf(stderr, "pure-ftpd was not running.\n Starting a new instance now...\n");
				[server startServer];
			}
			fprintf(stderr, "Done.\n");
		} else if (strcmp(argv[1], "status") == 0) {
			if ([server isServerRunning]){
				fprintf(stderr, "pure-ftpd is running.\n");
			} else {
				fprintf(stderr, "pure-ftpd is not running.\n");
			}
		}else if (strcmp(argv[1], "help") == 0) {
            usage();
		}
		
		[server release];
    }
    [pool release];
    return 0;
}
