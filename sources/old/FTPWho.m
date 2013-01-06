/*
    PureFTPd Manager
    Copyright (C) 2003 Jean-Matthieu Schaffhauser <jean-matthieu@users.sourceforge.net>

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


#import "FTPWho.h"

@implementation FTPWho

-(id) init
{
    self=[super init];
    if(self){
        ftpwho=nil;
        ftpUsage = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(void) dealloc
{
    [ftpwho release];
    [ftpUsage release];
    [super dealloc];
}

-(void)queryServer
{
    if (self == nil);
        [self init];
    
    ftpwho = [[NSTask alloc] init];
    NSPipe *pipe=[[NSPipe alloc] init];
    NSFileHandle *handle;
    NSData *data;
    
    [ftpwho setLaunchPath:PureFTPWho];
    [ftpwho setArguments:[NSArray arrayWithObjects:@"-p", nil]];
    
    [ftpwho setStandardOutput: pipe];
    //[ftpwho setStandardError: pipe];
    handle = [pipe fileHandleForReading];
    
     // remove old dictionary
    [[NSFileManager defaultManager] removeFileAtPath:PureFTPUsageFile  handler:nil];
    
    [ftpwho launch];
    
    //[NSThread detachNewThreadSelector:@selector(copyData:)
    //    toTarget:self withObject:handle];
    while([data=[handle availableData] length]) { // until EOF (check reference)
        NSString *string=[[NSString alloc] initWithData:data
                encoding:NSASCIIStringEncoding];
        [string writeToFile:PureFTPUsageFile atomically:YES];

        [string release];
    }
}

- (void)copyData:(NSFileHandle*)handle {
    NSAutoreleasePool *pool=[[NSAutoreleasePool alloc] init];
    NSData *data;

    while([data=[handle availableData] length]) { // until EOF (check reference)
        NSString *string=[[NSString alloc] initWithData:data
                encoding:NSASCIIStringEncoding];
        [string writeToFile:PureFTPUsageFile atomically:YES];

        [string release];
    }
    
    [pool release];
}

-(NSTask *)ftpwho
{
    return ftpwho;
}

-(NSMutableArray *)ftpUsage
{
    if(ftpUsage)
        [ftpUsage release];
    
    ftpUsage = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPUsageFile];    
    
    return [ftpUsage objectForKey:@"user-info"];
}
@end
