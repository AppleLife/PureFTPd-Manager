//
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

#import "NSXLogParser.h"


@implementation NSXLogParser

-(id) initWithInfoCapacity:(int) capacity
{
    self = [super init];
    if (self)
    {
        arrayCapacity = capacity;
        completeArray = [[NSMutableArray alloc] init];
    }
    return self;
}

-(void) dealloc
{
    [completeArray release];
    [super dealloc];
}

-(NSMutableArray *) infoArray
{
    return completeArray;
}

-(void) clearLoginfoArray
{
    [completeArray removeAllObjects];
}

-(void) parseLine:(NSString *)aLine withPattern:(NSString *)aPattern
{
    pcre *re;
    const char *error;
    loginfoArray = [[NSMutableArray alloc] initWithCapacity:arrayCapacity];
    
    int erroffset;
    
    int ovector[OVECCOUNT];
    int subject_length;
    int rc, i;
    
    NSString *substring;
    
    //NSLog(@"%@", [aSubject description]);
    
    //snprintf(pattern, [aPattern cStringLength], "%s", [aPattern cString]);
    //snprintf(subject,  [aSubject cStringLength], "%s", [aSubject cString]);
    
    const char *pattern = [[aPattern description] cString];
    const char *subject = [[aLine description] cString];
    
    
    subject_length = (int)strlen(subject);
    
    
    /*************************************************************************
    * Now we are going to compile the regular expression pattern, and handle *
    * and errors that are detected.                                          *
    *************************************************************************/
    
    re = pcre_compile(
                      pattern,              /* the pattern */
                      0,                    /* default options */
                      &error,               /* for error message */
                      &erroffset,           /* for error offset */
                      NULL);                /* use default character tables */
                      
    /* Compilation failed: print the error message and exit */
                      
    if (re == NULL)
    {
        printf("PCRE compilation failed at offset %d: %s\n", erroffset, error);
		[loginfoArray release];
        return;
    }
                      
                      
    /*************************************************************************
    * If the compilation succeeded, we call PCRE again, in order to do a     *
    * pattern match against the subject string. This just does ONE match. If *
    * further matching is needed, it will be done below.                     *
    *************************************************************************/
                      
    rc = pcre_exec(
                    re,                   /* the compiled pattern */
                    NULL,                 /* no extra data - we didn't study the pattern */
                    subject,              /* the subject string */
                    subject_length,       /* the length of the subject */
                    0,                    /* start at offset 0 in the subject */
                    0,                    /* default options */
                    ovector,              /* output vector for substring information */
                    OVECCOUNT);           /* number of elements in the output vector */
                                
    /* Matching failed: handle error cases */
                                
    if (rc < 0)
    {
        /*switch(rc)
        {
            case PCRE_ERROR_NOMATCH:
                //fprintf(stderr,"No match\n"); 
                break;
            
            Handle other special cases if you like
            
            default: 
                //fprintf(stderr,"Matching error %d\n", rc); 
                break;
        }*/
		
		[loginfoArray release];
		
		if (re != NULL)
			free(re);
		
		
        return;
    }
                                
    /* Match succeded */
    //fprintf(stderr, "\nMatch succeeded at offset %d\n", ovector[0]);
                   
                                     
    /*************************************************************************
    * We have found the first match within the subject string. If the output *
    * vector wasn't big enough, set its size to the maximum. Then output any *
    * substrings that were captured.                                         *
    *************************************************************************/
                                    
    /* The output vector wasn't big enough */
                                
    if (rc == 0)
    {
        rc = OVECCOUNT/3;
    }
                                     
    /* Show substrings stored in the output vector by number. Obviously, in a real
    application you might want to do things other than print them. */
                                     
                                    
    for (i = 0; i < rc; i++)
    {
        char *substring_start = (char *) (subject + ovector[2*i]);
        int substring_length = ovector[2*i+1] - ovector[2*i];
        substring = [NSString stringWithFormat:@"%.*s",substring_length, substring_start];
        [loginfoArray insertObject:substring atIndex:i];
        
    }
	
	
    
    [completeArray addObject:[NSArray arrayWithArray:loginfoArray]];
	
	[loginfoArray release];
	
	if (re != NULL)
		free(re);
	
}

@end
