
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

#import "SSLPane.h"
#import "defines.h"

@implementation SSLPane
- (id) initWithBundle:(NSBundle *) bundle {
    self = [super initWithBundle:bundle] ;
    
    return self ;
}

#pragma mark Preference Pane view delegates
- (void) mainViewDidLoad {
    pureFTPPreferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    fm = [NSFileManager defaultManager];
    
    [self loadPreferences];
    [self showTLS:tlsPopUp];
    //create ssl directory if it does not exists yet
    if (![fm fileExistsAtPath:@"/etc/pure-ftpd/ssl"])
	[fm createDirectoryAtPath:@"/etc/pure-ftpd/ssl" attributes:nil];
    modified=NO;
}


- (void) willUnselect {
    if(modified) {
        [self savePreferences];    
    }   
    [pureFTPPreferences release];       
}


#pragma mark Load / Save preferences

-(void)activateUI
{
    if([fm fileExistsAtPath:PureFTPSSLCertificate])
    {
	[viewBtn setEnabled:YES];
	[removeBtn setEnabled:YES];
	[createBtn setEnabled:NO];
    }
    else
    {
	[viewBtn setEnabled:NO];
	[removeBtn setEnabled:NO];
	[createBtn setEnabled:YES];
        [tlsPopUp selectItemAtIndex:0];
    }
}

-(void) restrictSSLFileAttributes
{
    NSNumber *posixPerm = [[NSNumber alloc] initWithInt:0600];
    NSMutableDictionary *attributes =[NSMutableDictionary dictionaryWithObject:posixPerm forKey:@"NSFilePosixPermissions"];
    if ([fm fileExistsAtPath:PureFTPSSLCertificate])
	[fm changeFileAttributes:attributes atPath:PureFTPSSLCertificate];
}

-(void) loadPreferences{
     [self activateUI];
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    [tlsPopUp selectItemAtIndex:[[preferences objectForKey:PureFTPTLSBehaviour] intValue]];
    [preferences release];
}

-(void) savePreferences{
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    
    NSString *tlsbehaviour = [NSString stringWithFormat:@"%d", [[tlsPopUp selectedItem] tag]];
    [preferences setObject:tlsbehaviour forKey:PureFTPTLSBehaviour];
    
    NSNumber *update = [[NSNumber alloc] initWithInt:1];
    [preferences setObject:update forKey:PureFTPPrefsUpdated];
    
    //NSLog(@"Saving PureFTPD preferences - SSL Pane");
    [preferences writeToFile:PureFTPPreferenceFile atomically:YES];

    [preferences release];
    [update release];
    [fm removeFileAtPath:@"/tmp/certConfig" handler:nil];
    modified = NO;
}

- (IBAction)didModify:(id)sender
{
    modified=YES;
}

#pragma mark Actions on existing certificate
- (IBAction)removeCert:(id)sender
{
    if (NSRunCriticalAlertPanel(NSLocalizedString(@"You are about to delete your SSL Certificate",@"You are about to delete your SSL certificate"),
				NSLocalizedString(@"Your certificate will be remove from your system. Do you want to continue ?",@"Your certificate will be remove from your system. Do you want to continue ?"),
				nil,NSLocalizedString(@"Cancel", @"Cancel"),nil) == NSOKButton)
	[fm removeFileAtPath:PureFTPSSLCertificate handler:nil];
    [self activateUI];
    modified=YES;
}

- (IBAction)showTLS:(id)sender
{
	
    switch ([sender indexOfSelectedItem]){
	case 0:
	    [sslField setStringValue:NSLocalizedString(@"Support for SSL/TLS is disabled.", @"Support for SSL/TLS is disabled.")];
	    break;
	case 1:
	    [sslField setStringValue:NSLocalizedString(@"Clients can connect either the traditional way or through an SSL/TLS layer.", @"Clients can connect either the traditional way or through an SSL/TLS layer.")];
	    break;
	case 2:
	    [sslField setStringValue:NSLocalizedString(@"Cleartext sessions are refused and only SSL/TLS compatible clients are accepted.", @"Cleartext sessions are refused and only SSL/TLS compatible clients are accepted.")];
		break;
    }
    modified = YES;
}

#pragma mark Import a cert or generate a self-signed cert
- (IBAction)importCert:(id)sender
{
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:NO];
    [oPanel setCanChooseFiles:YES];
    [oPanel setResolvesAliases:NO];
    NSString *activeUser = nil;
    
    [oPanel beginSheetForDirectory:@"/" file:nil types:nil 
		    modalForWindow:certWindow
		     modalDelegate: self
		    didEndSelector: @selector(importDidEnd:returnCode:contextInfo:)
                       contextInfo: nil];
    
    
}

- (void)importDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
    [NSApp stopModal];
    if (returnCode == NSOKButton)
    {        
	if ([fm copyPath:[[sheet filenames] objectAtIndex:0] toPath:PureFTPSSLCertificate handler:nil])
	{
	    modified =YES;
	    [self restrictSSLFileAttributes];
	}
	[certWindow orderOut:self];
	[self activateUI];
    }   
}


- (IBAction)startCert:(id)sender
{
    [NSApp beginSheet: newCertWindow
       modalForWindow: certWindow
	modalDelegate: self
       didEndSelector: @selector(newCertDidEnd:returnCode:contextInfo:)
	  contextInfo: nil];
    [NSApp runModalForWindow: newCertWindow];
    // Sheet is up here.
    [NSApp endSheet: newCertWindow];
    [newCertWindow orderOut: self];
}

- (void)newCertDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
    modified =YES;
    [self restrictSSLFileAttributes];
    [certWindow orderOut:self];
    [self activateUI];
}

#pragma mark View Certificate
- (IBAction)closeView:(id)sender
{
    [NSApp stopModal];
}

- (IBAction)viewCert:(id)sender
{
    NSString *certString = [[NSString alloc] initWithContentsOfFile:PureFTPSSLCertificate];
    [certTextView replaceCharactersInRange:NSMakeRange(0,0) withString:certString];
    [NSApp beginSheet: viewCertWindow
       modalForWindow: [NSApp mainWindow]
	modalDelegate: nil
       didEndSelector: nil
	  contextInfo: nil];
    [NSApp runModalForWindow: viewCertWindow];
    // Sheet is up here.
    [NSApp endSheet: viewCertWindow];
    [viewCertWindow orderOut: self];
    [certTextView replaceCharactersInRange:NSMakeRange(0,[certString length]) withString:@""];
    [certString release];
}

#pragma mark PopUp Menu Item validation
- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    if (![fm fileExistsAtPath:PureFTPSSLCertificate]){
        switch ([item tag]){
            case 0:
                return YES;
                break;
            case 1:
                return NO;
                break;
            case 2:
                return NO;
                break;
        }
    }
    
    return YES;
}

    

@end
