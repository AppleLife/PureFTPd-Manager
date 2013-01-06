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

#import "SystemPane.h"
#import "defines.h"
#import "MVPreferencesController.h"

@implementation SystemPane
- (id) initWithBundle:(NSBundle *) bundle {
    self = [super initWithBundle:bundle] ;
    
    return self ;
}

- (void) dealloc {
	[super dealloc];
}

-(void) loadPreferences{
    
    [startupSwitch setState:[[pureFTPPreferences objectForKey:PureFTPAtStartup] intValue]];
    int forceStartup = [[pureFTPPreferences objectForKey:PureFTPServerMode] intValue];
    [serverModePopUp selectItemAtIndex:forceStartup];
    oldServerMode = forceStartup;
	
    if (forceStartup == 0){
        [startupSwitch setEnabled:NO];
		[rdvSwitch setEnabled:NO];  
		[rdvSwitch setState:NSOnState];
		[rdvField setEditable:NO];
		[rdvField setStringValue:[[NSProcessInfo processInfo] hostName]];
    }
    
    [managerUpdateSwitch setState:[[pureFTPPreferences objectForKey:PureFTPAutoUpdate] intValue]];
    
    // Rendezvous
    if (![[pureFTPPreferences objectForKey:PureFTPRendezVous] isEqualToString:@""])
    {
        [rdvSwitch setState:1];
        [rdvField setStringValue:[pureFTPPreferences objectForKey:PureFTPRendezVous]];
    }
    else
    {
        NSString *rdvName = [NSString stringWithFormat:@"%@", [[NSProcessInfo processInfo] hostName]];
        [rdvSwitch setState:0];
        [rdvField setStringValue: rdvName];
    }
	
	id value = [pureFTPPreferences objectForKey:PureFTPGradient];
	int state = 0;
	if ((value) == nil || ([value intValue] == 1))
		state=1;
		
	[gradientSwitch setState:state];

    [userBaseDirField setStringValue:[pureFTPPreferences objectForKey:PureFTPUserBaseDir]];
    [vhostBaseDirField setStringValue:[pureFTPPreferences objectForKey:PureFTPVHostBaseDir]];
}

-(void) savePreferences{
    NSMutableDictionary *preferences = [NSMutableDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile];

    
    NSNumber *atStartup = [NSNumber numberWithInt:[startupSwitch state]];
    [preferences setObject:atStartup forKey:PureFTPAtStartup];
    
	NSNumber *gradient = [NSNumber numberWithInt:[gradientSwitch state]];
	[preferences setObject:gradient forKey:PureFTPGradient];
	
    NSNumber *autoUpdate = [NSNumber numberWithInt:[managerUpdateSwitch state]];
    [preferences setObject:autoUpdate forKey:PureFTPAutoUpdate];
	
    NSNumber *serverMode = [NSNumber numberWithInt:[serverModePopUp indexOfSelectedItem]];
    [preferences setObject:serverMode forKey:PureFTPServerMode];
	
	if (oldServerMode != [serverMode intValue])
		[preferences setObject:[NSNumber numberWithInt:1] forKey:PureFTPServerModeModified];
	else
		[preferences setObject:[NSNumber numberWithInt:0] forKey:PureFTPServerModeModified];
    
    //rendezvous
    if ([rdvSwitch state])
        [preferences setObject:[rdvField stringValue] forKey:PureFTPRendezVous];
    else
        [preferences setObject:@"" forKey:PureFTPRendezVous];
    
    [preferences setObject:[userBaseDirField stringValue] forKey:PureFTPUserBaseDir];
    [preferences setObject:[vhostBaseDirField stringValue] forKey:PureFTPVHostBaseDir];

    NSNumber *update = [NSNumber numberWithInt:1];
    [preferences setObject:update forKey:PureFTPPrefsUpdated];
     
    //NSLog(@"Saving PureFTPD Preferences - Mac OS X ");
    [preferences writeToFile:PureFTPPreferenceFile atomically:YES];
    
    modified = NO;
    

}

// Delegates
// TextFields
- (void)controlTextDidChange:(NSNotification *)aNotification
{
    modified = YES;
}



- (void)configureStartup{
    int atStartup = [startupSwitch state];
    NSString *onOff = nil;
    switch (atStartup){
        case 0:
            onOff = @"PUREFTPD=-NO-";
            break;
        case 1 :
            onOff = @"PUREFTPD=-YES-";
            break;
    }
    
    NSString *hostConfig = [NSString stringWithContentsOfFile:@"/etc/hostconfig"];
    NSString *newConfig;
    NSRange pRange = [hostConfig rangeOfString:@"PUREFTPD"];
    
    if (pRange.length==0) // Can't find entry in /etc/hostconfig; we add it
        newConfig = [NSString stringWithString:[hostConfig stringByAppendingString:[NSString stringWithFormat:@"\n%@\n",onOff]]];
    else 
    {
        NSRange lineRange = [hostConfig lineRangeForRange:pRange];
        NSString *before = [NSString stringWithString:[hostConfig substringToIndex:lineRange.location]];
        NSString *after = [NSString stringWithString:[hostConfig substringFromIndex:NSMaxRange(lineRange)]];
        
        newConfig = [NSString stringWithFormat:@"%@%@\n%@", before, onOff, after];
    }
    
    [newConfig writeToFile:@"/etc/hostconfig" atomically:YES];
    
    switch ([serverModePopUp indexOfSelectedItem]){
        case 0:
            [self setupXinetd];
            break;
        case 1:
            [self setupStandAlone];
            break;
    }
}

- (void)setupXinetd
{
    int atStartup = [startupSwitch state];
    NSString *disable =nil;

    switch (atStartup){
        case 0:
            disable = @"yes";
            break;
        case 1 :
            disable = @"no";
            break;
    }
    NSArray *args = [NSArray arrayWithArray:[self generateArguments]];
    SInt32 MacVersion;
    Gestalt(gestaltSystemVersion, &MacVersion);
	if (MacVersion < 0x1040){
		NSString *ftpFile = [NSString stringWithFormat:@"service ftp\n\
{\n\
\tdisable = %@\n\
\tsocket_type = stream\n\
\twait = no\n\
\tuser = root\n\
\tserver = /usr/local/sbin/pure-ftpd\n\
\tserver_args = %@\n\
\tgroups = yes\n\
\tflags = REUSE\n}", disable, [args componentsJoinedByString:@" "]];
    
		[ftpFile writeToFile:@"/etc/xinetd.d/ftp" atomically:NO];
	} else { // 10.4
		NSMutableDictionary *launchDaemon = [NSMutableDictionary dictionaryWithContentsOfFile:@"/System/Library/LaunchDaemons/ftp.plist"];
		[launchDaemon setObject:@"org.pureftpd.macosx" forKey:@"Label"];
		[launchDaemon setObject:PureFTPDCMD forKey:@"Program"];
		[launchDaemon setObject:args forKey:@"ProgramArguments"];
		[launchDaemon writeToFile:@"/System/Library/LaunchDaemons/ftp.plist" atomically:YES];
	}
	
    
}

- (void)setupStandAlone
{
	SInt32 MacVersion;
    Gestalt(gestaltSystemVersion, &MacVersion);
	if (MacVersion < 0x1040){
		NSString *originalXinetd = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"ftposx" ofType:nil]];
		[originalXinetd writeToFile:@"/etc/xinetd.d/ftp" atomically:NO];
	} else {
		NSMutableDictionary *launchDaemon = [NSMutableDictionary dictionaryWithContentsOfFile:@"/System/Library/LaunchDaemons/ftp.plist"];
		[launchDaemon setObject:[NSNumber numberWithInt:1] forKey:@"Disabled"];;
		[launchDaemon writeToFile:@"/System/Library/LaunchDaemons/ftp.plist" atomically:YES];
	}
}

- (IBAction)didModify:(id)sender
{
    modified = YES;
}

- (IBAction)toggleStartup:(id)sender
{
    if ([sender isEqualTo:serverModePopUp]){
        int selectedItem = [sender indexOfSelectedItem];
        switch(selectedItem) {
            case 0:
                [startupSwitch setEnabled:NO];  
                [startupSwitch setState:NSOnState];
				[rdvSwitch setEnabled:NO];  
                [rdvSwitch setState:NSOnState];
				[rdvField setEditable:NO];
				[rdvField setStringValue:[[NSProcessInfo processInfo] hostName]];
				  
                break;
            case 1:
                [startupSwitch setEnabled:YES];  
                [startupSwitch setState:NSOnState];  
				[rdvSwitch setEnabled:YES];  
				[rdvSwitch setState:NSOnState];
				[rdvField setEditable:YES];
                break;
        }
    } else if ([sender isEqualTo:startupSwitch])
    {
        switch ([sender state]){
            case 0:
                [serverModePopUp setEnabled:NO];
                [serverModePopUp selectItemAtIndex:1];
                break;
            case 1 :
                [serverModePopUp setEnabled:YES];
                break;
        }
    }
   
   [self configureStartup];
   
    modified = YES;
}


- (IBAction)chooseDir:(id)sender
{
    
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	if ([oPanel respondsToSelector:@selector(setCanCreateDirectories:)])
		[oPanel setCanCreateDirectories:YES];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:NO];
    [oPanel setResolvesAliases:NO];
	
	NSString *path = nil;
	if ([sender tag])
		path=[vhostBaseDirField stringValue];
	else 
		path = [userBaseDirField stringValue];
	BOOL isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]
		|| !isDir)
		path=@"/"; 
		
	[oPanel beginSheetForDirectory:path file:nil types:nil
					modalForWindow:[NSApp mainWindow]
                       modalDelegate: self
                       didEndSelector: @selector(openPanelDidEnd:returnCode:contextInfo:)
                       contextInfo: (void *)[sender tag]];
    
}

- (void)openPanelDidEnd:(NSOpenPanel *)sheet returnCode:(int)returnCode contextInfo:(void *) contextInfo
{
    [NSApp stopModal];
    if (returnCode == NSOKButton)
    {        
        modified = YES;
        
        if ((int)contextInfo==0)
            [userBaseDirField setStringValue:[[sheet filenames] objectAtIndex:0]];
        else if ((int)contextInfo==1)
            [vhostBaseDirField setStringValue:[[sheet filenames] objectAtIndex:0]];
    }   
        

}



- (void) mainViewDidLoad {
    pureFTPPreferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
	modified=NO;
    [self loadPreferences];
    
}

- (void) willUnselect {
    if(modified)
        [self savePreferences];  
    [pureFTPPreferences release];       
}

-(NSMutableArray *) generateArguments 
{
    NSMutableDictionary *serverPreferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    NSMutableArray *arguments = [[[NSMutableArray alloc] init] autorelease];
    
    /* Prepare server arguments...
        
        ...from fields
        if (![[serverPreferences objectForKey:PureFTP] isEqualToString:@""])
    {
            [arguments addObject:@"-"];
            [arguments addObject:[serverPreferences objectForKey:PureFTP]];
    }
    
    ...from switches
        if ([[serverPreferences objectForKey:PureFTP] intValue] == 1)
    {
            [arguments addObject:@"-"];
    }
    */
    
    // Port
    if (![[serverPreferences objectForKey:PureFTPPort] isEqualToString:@""] && ([serverModePopUp indexOfSelectedItem] == 1))
    {	
        //NSNumber *port = [[NSNumber alloc] initWithInt:[ intValue]];
        [arguments addObject:@"-S"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPPort]];
    }
    
    // Timeout
    if (![[serverPreferences objectForKey:PureFTPTimeout] isEqualToString:@""])
    {
        [arguments addObject:@"-I"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPTimeout]];
    }
    
    // PassiveRange
    if (![[serverPreferences objectForKey:PureFTPPassiveRange] isEqualToString:@""])
    {
        [arguments addObject:@"-p"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPPassiveRange]];
    }
    
    //Max Users
    if (![[serverPreferences objectForKey:PureFTPMaxUsers] isEqualToString:@""])
    {
        [arguments addObject:@"-c"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPMaxUsers]];
    }
    
    // Max sessions per IP
    if (![[serverPreferences objectForKey:PureFTPMaxSessions] isEqualToString:@""])
    {
        [arguments addObject:@"-C"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPMaxSessions]];
    }
    
    // FXP
    switch([[serverPreferences objectForKey:PureFTPFXP] intValue]){
        case 0:
            // FXPDisabled
            break;
        case 1:
        {
            // FXPEveryone
            [arguments addObject:@"-W"];
            break;
        }
        case 2:
        {
            // FXPAuthOnly
            [arguments addObject:@"-w"];
            break;
        }
    }
    
    // Rendezvous
    if (![[serverPreferences objectForKey:PureFTPRendezVous] isEqualToString:@""]  && ([serverModePopUp indexOfSelectedItem] == 1))
    {
        [arguments addObject:@"-v"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPRendezVous]];
    }
    
    // Resolve hostnames
    if ([[serverPreferences objectForKey:PureFTPResolvName] intValue] == 1)
    {
        [arguments addObject:@"-H"];
    }
    
    // Force Active Mode
    if ([[serverPreferences objectForKey:PureFTPForceActive] intValue] == 1)
    {
        [arguments addObject:@"-N"];
    }
    
    // Force IP
    if (![[serverPreferences objectForKey:PureFTPForceIP] isEqualToString:@""])
    {
        [arguments addObject:@"-P"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPForceIP]];
    }
    
    // Disk usage
    if (![[serverPreferences objectForKey:PureFTPMaxPartition] isEqualToString:@""])
    {
        [arguments addObject:@"-k"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPMaxPartition]];
    }
    
    // Max Load
    if (![[serverPreferences objectForKey:PureFTPMaxLoad] isEqualToString:@""])
    {
        [arguments addObject:@"-m"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPMaxLoad]];
    }
    
    // User Speed Limit
    if (![[serverPreferences objectForKey:PureFTPUserSpeedLimit] isEqualToString:@""])
    {
        [arguments addObject:@"-T"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPUserSpeedLimit]];
    }
	
	//Recursion Limit
    NSString *rl = [serverPreferences objectForKey:PureFTPRecursionLimit];
    if ((rl != nil) && ([rl length] > 0))
    {
        [arguments addObject:@"-L"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPRecursionLimit]];
    }
    
    // Extra Args
    if (![[serverPreferences objectForKey:PureFTPExtraArguments] isEqualToString:@""])
    {
        [arguments addObject:[serverPreferences objectForKey:PureFTPExtraArguments]];
    }
    
    // Auth methods
    NSMutableArray *authMethods = [NSArray arrayWithArray:[serverPreferences objectForKey:PureFTPAuthentificationMethods]];
    NSMutableDictionary *authDict;
    NSEnumerator *myEnumerator = [authMethods objectEnumerator];
    
    while (authDict = [myEnumerator nextObject])
    {
        if ([[authDict objectForKey:@"auth.type"] isEqualToString:@"PureDB"]){
            NSString *authArg = [NSString stringWithFormat:@"-lpuredb:%@", [authDict objectForKey:@"auth.file"]];
            [arguments addObject:authArg];
        }
        else if ([[authDict objectForKey:@"auth.type"] isEqualToString:@"LDAP"]){
            NSString *authArg = [NSString stringWithFormat:@"-lldap:%@", [authDict objectForKey:@"auth.file"]];
            [arguments addObject:authArg];
        }
        else if ([[authDict objectForKey:@"auth.type"] isEqualToString:@"MySQL"]){
            NSString *authArg = [NSString stringWithFormat:@"-lmysql:%@", [authDict objectForKey:@"auth.file"]];
            [arguments addObject:authArg];
        }
        else if ([[authDict objectForKey:@"auth.type"] isEqualToString:@"PostgreSQL"]){
            NSString *authArg = [NSString stringWithFormat:@"-lpgsql:%@", [authDict objectForKey:@"auth.file"]];
            [arguments addObject:authArg];
        }
        else if ([[authDict objectForKey:@"auth.type"] isEqualToString:@"Unix"]){
	    // Panther compatible 
            NSString *authArg = [NSString stringWithString:@"-lunix"];
            [arguments addObject:authArg];
        }
        else if ([[authDict objectForKey:@"auth.type"] isEqualToString:@"PAM"]){
	    // Panther compatible 
            NSString *authArg = [NSString stringWithString:@"-lpam"];
            [arguments addObject:authArg];
        }
    }
    
    
    // Create homedir automatically
    if ([[serverPreferences objectForKey:PureFTPCreateHomeDir] intValue] == 1)
    {
        [arguments addObject:@"-j"];
    }
    
    // Disable anonymous access
    if ([[serverPreferences objectForKey:PureFTPNoAnonymous] intValue] == 1)
    {
        [arguments addObject:@"-E"];
    }
    
    // Disable upload for anonymous users
    if ([[serverPreferences objectForKey:PureFTPAnonymousNoUpload] intValue] == 1)
    {
        [arguments addObject:@"-i"];
    }
    
    // Anonymous can create dir
    if ([[serverPreferences objectForKey:PureFTPAnonymousCreateDir] intValue] == 1)
    {
        [arguments addObject:@"-M"];
    }
    
    // Anonymous can't dld files owned by anonymous
    if ([[serverPreferences objectForKey:PureFTPAnonymousNoDownload] intValue] == 1)
    {
        [arguments addObject:@"-s"];
    }
    
    // Anonymous Ratio 
    if (![[serverPreferences objectForKey:PureFTPAnonymousRatio] isEqualToString:@""])
    {
        [arguments addObject:@"-q"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPAnonymousRatio]];
    }
    
    // Anonymous speed limit
    if (![[serverPreferences objectForKey:PureFTPAnonymousSpeedLimit] isEqualToString:@""])
    {
        [arguments addObject:@"-t"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPAnonymousSpeedLimit]];
    }
    
    // Log Format
    if ([[serverPreferences objectForKey:PureFTPLogOnOff] intValue] == 1)
    {   
	NSString *logOptions = [NSString stringWithFormat:@"-O%@:%@", 
	    [[serverPreferences objectForKey:PureFTPLogFormat] lowercaseString], 
	    [serverPreferences objectForKey:PureFTPLogLocation]];
        //[arguments addObject:@"-O"];
	[arguments addObject:logOptions];
    }
    
    // TLS Behaviour PureFTPTLSBehaviour
    if (![[serverPreferences objectForKey:PureFTPTLSBehaviour] isEqualToString:@""])
    {
	[arguments addObject:@"-Y"];
        [arguments addObject:[serverPreferences objectForKey:PureFTPTLSBehaviour]];
    }
    
	// Umask setting
	NSString *fileMask = nil;
	NSString *folderMask = nil;
	
	if ( ((fileMask = [serverPreferences objectForKey:PureFTPFileCreationMask]) != nil) &&
		 ((folderMask = [serverPreferences objectForKey:PureFTPFolderCreationMask]) !=nil) )
	{
		[arguments addObject:@"-U"];
		[arguments addObject:[NSString stringWithFormat:@"%@:%@", fileMask, folderMask]];
	}

	
    [serverPreferences release];
    return arguments;
    
    
}


@end

