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

#import "DirAliasesPane.h"
#import "defines.h"

@implementation DirAliasesPane
- (id) initWithBundle:(NSBundle *) bundle {
    self = [super initWithBundle:bundle] ;
    
    return self ;
}

- (void) dealloc {
    [dirAliases release];
	[super dealloc];
}

- (void) mainViewDidLoad {
    modified = NO;
    dirAliases = [[NSMutableArray alloc] init];
    [self parseAliases];
}

- (void) willUnselect {
    if (modified)
	[self saveAliases];
}

- (void)parseAliases
{
    NSString *myFile = [NSString stringWithContentsOfFile:PureFTPDirAliases];
    NSMutableArray *tmpArray = nil;
    NSDictionary *infoDict;
    
    int i=0, j=0;
    if ((nil != myFile) && (![myFile isEqualToString:@""]))
    {
	tmpArray = [[NSMutableArray alloc] initWithArray:[myFile componentsSeparatedByString:@"\n"]];
	NSEnumerator *arrayEnum = [tmpArray objectEnumerator];
	NSString *salc;
	// Remove comments if any
	while (salc = [arrayEnum nextObject])
	{
	    if (![salc isEqualToString:@""]){
		if ([[salc substringWithRange:NSMakeRange(0,1)] isEqualToString:@"#"]){
		    [tmpArray removeObjectAtIndex:i-j];
		    j++;
		}
	    }
	    
	    else
	    {
		[tmpArray removeObjectAtIndex:i-j];
		j++;
	    }
	    i++;
	}
	
	i = 0;
	while (i<[tmpArray count])
	{
	    NSArray *objects = [NSArray arrayWithObjects:[tmpArray objectAtIndex:i], [tmpArray objectAtIndex:i+1], nil];
	    NSArray *keys = [NSArray arrayWithObjects:@"alias.name", @"alias.folder", nil];
	    infoDict = [NSDictionary dictionaryWithObjects:objects forKeys:keys];
	    
	    [dirAliases addObject:infoDict];
	    i+=2;
	}
    }
    
    if (nil != tmpArray)
	[tmpArray release];
}

- (void)saveAliases
{
    
    NSMutableArray *saveArray = [[NSMutableArray alloc] init];
    NSString *saveFile = nil;
    NSDictionary *infoDict;
    
    NSEnumerator *aliasEnum = [dirAliases objectEnumerator];
    while (infoDict = [aliasEnum nextObject])
    {
	[saveArray addObject:[infoDict objectForKey:@"alias.name"]];
	[saveArray addObject:[infoDict objectForKey:@"alias.folder"]];
    }
    
    saveFile = [saveArray componentsJoinedByString:@"\n"];
    [saveFile writeToFile:PureFTPDirAliases atomically:YES];
    [saveArray release];
    
    NSMutableDictionary *preferences = [[NSMutableDictionary alloc] initWithContentsOfFile:PureFTPPreferenceFile];
    
    NSNumber *update = [[NSNumber alloc] initWithInt:1];
    [preferences setObject:update forKey:PureFTPPrefsUpdated];
    
    //NSLog(@"Saving PureFTPD  Directory Aliases");
    [preferences writeToFile:PureFTPPreferenceFile atomically:YES];
    [update release];
    [preferences release];
    modified = NO;
    
}


- (IBAction)addAlias:(id)sender
{
    [folderField setStringValue:@""];
    [nameField setStringValue:@""];
    [NSApp beginSheet: addWindow
       modalForWindow: [NSApp mainWindow]
	modalDelegate: nil
       didEndSelector: nil
	  contextInfo: nil];
    [NSApp runModalForWindow: addWindow];
    // Sheet is up here.
    [NSApp endSheet: addWindow];
    [addWindow orderOut: self];
}

- (IBAction)addCancel:(id)sender
{
    [NSApp stopModal];
}

- (IBAction)addOK:(id)sender
{
    NSMutableDictionary *infoDict;
    
    infoDict = [[NSMutableDictionary alloc] init];
    [infoDict setObject:[nameField stringValue] forKey:@"alias.name"];
    [infoDict setObject:[folderField stringValue] forKey:@"alias.folder"];
    
    [dirAliases addObject:infoDict];
    [aliasesTable reloadData];
    [infoDict release];
    
    //else if 
    [NSApp stopModal];
    modified = YES;    
}

- (IBAction)chooseDir:(id)sender
{
    int result;
    NSOpenPanel *oPanel = [NSOpenPanel openPanel];
	if ([oPanel respondsToSelector:@selector(setCanCreateDirectories:)])
		[oPanel setCanCreateDirectories:YES];
    [oPanel setAllowsMultipleSelection:NO];
    [oPanel setCanChooseDirectories:YES];
    [oPanel setCanChooseFiles:NO];
    [oPanel setResolvesAliases:NO];
    NSString *activeUser = nil;
   
	NSString *path = [folderField stringValue];
	BOOL isDir = YES;
	if (![[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir]
		|| !isDir)
		path=@"/";
		
    
    result = [oPanel runModalForDirectory:path file:nil types:nil];
    if (result == NSOKButton)
        [folderField setStringValue:[[oPanel filenames] objectAtIndex:0]];
    
}

- (IBAction)removeAlias:(id)sender
{
    int row=[aliasesTable selectedRow];
    [dirAliases removeObjectAtIndex:row];
    [aliasesTable reloadData];
    modified = YES;
}

// NSTableView Datasource

- (int)numberOfRowsInTableView:(NSTableView*)tableView
{
    return [dirAliases count];
}

- (id)tableView:(NSTableView*)tableView objectValueForTableColumn:(NSTableColumn *)col row:(int)row
{
    NSDictionary *infoDict = [NSMutableDictionary dictionaryWithDictionary:[dirAliases objectAtIndex:row]];
    return [infoDict valueForKey:[col identifier]];
}

// NSTableView delegates
- (BOOL)tableView:(NSTableView *)aTableView shouldSelectRow:(int)rowIndex{
    [removeBtn setEnabled:YES];
    return YES;
}


@end
