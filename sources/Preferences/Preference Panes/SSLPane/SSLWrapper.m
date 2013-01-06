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

#import "SSLWrapper.h"
#import "defines.h"

@implementation SSLWrapper

- (IBAction)generateCert:(id)sender
{
    if ([[country stringValue] isEqualToString:@""] ||
	[[state stringValue] isEqualToString:@""] ||
	[[locality stringValue] isEqualToString:@""] ||
	[[organization stringValue] isEqualToString:@""] ||
	[[unit stringValue] isEqualToString:@""] ||
	[[name stringValue] isEqualToString:@""] ||
	[[email stringValue] isEqualToString:@""])
    {
	NSRunCriticalAlertPanel(NSLocalizedString(@"Incomplete form", @"Incomplete form"),
				NSLocalizedString(@"You must provide more information to generate a certificate.\n Please make sure you complete the whole form properly.", @"You must provide more information to generate a certificate\n Please make sure you complete the whole form properly."),
				nil,nil,nil);
	return;
    }
    
    NSString *configFile = [[NSString alloc] initWithFormat:@"\
    [ req ]\n \
    prompt = no\n \
    distinguished_name = req_distinguished_name\n \
    \n\
    dirstring_type = nobmp\n\
    \n\
    [ req_distinguished_name ]\n\
    C = %@\n\
    ST = %@\n\
    L = %@\n\
    O = %@\n\
    OU = %@\n\
    CN = %@\n\
    emailAddress=%@", [country stringValue], [state stringValue], [locality stringValue], [organization stringValue],
		      [unit stringValue], [name stringValue], [email stringValue]];
    
    if([configFile writeToFile:@"/tmp/certConfig" atomically:YES])
    {
	[wheel startAnimation:nil];
	[self createCert];
	
    }
    
    [wheel stopAnimation:nil];
    [configFile release];    
    [self closeWindow:nil];
}

- (void)createCert
{
    NSTask *sslreq = [[NSTask alloc] init];
    [sslreq setLaunchPath:@"/bin/sh"];
    NSArray *args = [NSArray arrayWithObjects:@"-c", 
		    [NSString stringWithFormat:@"openssl req -x509 -config /tmp/certConfig -nodes -newkey rsa:%@ -days %@ -keyout %@ -out %@", 
		    [bitsPopup titleOfSelectedItem], [day stringValue], PureFTPSSLCertificate, PureFTPSSLCertificate], nil];
    
    [sslreq setArguments:args];
    [sslreq launch];
    [sslreq waitUntilExit];
}

- (IBAction)closeWindow:(id)sender
{
   [NSApp stopModal];
}



@end
