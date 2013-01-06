/*
 *  purestats.m
 *  LogViewer
 *
 *  Created by Jean-Matthieu on 12/10/2004.
 *  Copyright 2004 __MyCompanyName__. All rights reserved.
 *
 */

#import <Cocoa/Cocoa.h>
#include <unistd.h>
#import "HTMLConverter.h"
#import "CSVConverter.h"

void usage();

void usage()
{
    char *license = "This program is free software; you can redistribute it and/or modify\n\
it under the terms of the GNU General Public License version 2 as published\n\
by the Free Software Foundation.\n";
    
    char *usage="\nUsage : purestats [-d] [-f] [-h] [-m] [-c] [-o output_directory]\n\
\t -d produces a very details HTML log file that display all transfer \n\tactivity for a user.\n\
\t -f displays full path to uploaded/dowloaded files.\n\
\t -h prints purestats usage.\n\
\t -m produces a month summary for each month, listing day by day download\n\tand upload traffic.\n\
\t -c produces CSV files.\n\
\t -o output_directory specifies the output directory for your HTML files.\n\
\tIf you do not specify a directory, it will save the file to your\n\
\tcurrent working directory.\n\
\tTHIS DIRECTORY MUST EXIST ON YOUR FILE SYSTEM.\n\n\
Examples:\n\
To get a very detailed HTML view of your server activity choose :\n\
\t # purestats -m -d -f -o /Library/WebServer/Documents/purestats/\n\
To get a monthly traffic overview, type:\n\
\t # purestats -m -o /Library/WebServer/Documents/purestats/\n\n\
NOTE : If you run purestats as root, it will automatically update PureFTPd\n\
Manager log system and then convert the up-to-date log to HTML files. It \n\
will simply convert your FTP statistics to HTML if you choose not to run it \n\
as root.\n";
    
    printf("%s\n%s\n", license, usage);
    
    return;
}

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    BOOL monthReport = NO;
    BOOL monthDetail = NO;
    BOOL fullPath = NO;
    BOOL useCSV = NO;
    NSString *saveDir = [[NSFileManager defaultManager] currentDirectoryPath];
    int ich;
    
    while ((ich = getopt (argc, argv, "mdfhco:")) != EOF) {
        switch (ich) {
            case 'm': 
                monthReport = YES;
                break;
            case 'd':
                monthDetail = YES;
                break;
            case 'f':
                fullPath = YES;
                break;
            case 'o':
                saveDir = [NSString stringWithCString:optarg];
                break;
			case 'c':
                useCSV=YES;
                break;
            case 'h':
                usage();
                return 0;
                break;
            default: /* Code when there are no parameters */
                break;
        }
    }
    
	
    if (!useCSV){
		HTMLConverter *htmlConverter = [[HTMLConverter alloc] initWithMonthSummary:monthReport withPath:fullPath andDetails:monthDetail];
		[htmlConverter convertToHTML];
    
		[htmlConverter exportToHTML:saveDir];
		[htmlConverter release];
	} else {
		CSVConverter *csv = [[CSVConverter alloc] init];
		[csv convertToCSV];
		
		[csv exportToCSV:saveDir];
		[csv release];
	}
    [pool release];
    return 0;
}



