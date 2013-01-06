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

#import "StatusManager.h"

// The pointer to the singleton instance
static StatusManager *theStatusManager = nil;

#pragma mark 
#pragma mark #--==> Weak Reference for our OutlineView <==--#

@implementation WeakReference
+(id)weakReferenceWithParent:(id)_parent {
    id weakRef=[[[WeakReference alloc] init] autorelease];
    [weakRef setParent:_parent];
return weakRef;
}

-(void)setParent:(id)_parent {
parent=_parent;
}

-(id)parent {
return parent;
}
@end

@implementation StatusManager

#pragma mark 
#pragma mark #--==> StatusManager initialization <==--#
- (id)init
{
    self = [super init];
    if (self) {
	myUsage = [[FTPUsage alloc] init];
	usersArray = [[NSMutableArray alloc] init];
	pureController = [PureController getInstance];
	queryInterval = nil;
	}
    return self;
}

- (void)dealloc
{
    [myUsage release];
    [usersArray release];
    [queryInterval release];
    [pureController release];
    [super dealloc];
}


/* Get the singleton instance of this class */
+(id) getInstance
{
    	// TODO: Mutex Begin
	if (theStatusManager == nil) {
		theStatusManager = [[StatusManager alloc] init];
	}
	// TODO: Mutex End
	return theStatusManager;
}


#pragma mark 
#pragma mark #--==> Query and status updates <==--#

-(void)updateStatus
{
    int bwUsage=0;
    id index;
    
    [[pureController closeSessionButton] setEnabled:NO];
        
    NSEnumerator *bwenum = [[myUsage usersDB] objectEnumerator];
    while (index = [bwenum nextObject])
        bwUsage+=[[index objectForKey:@"bandwidth"] intValue];
        
    NSString *sessions = [NSString stringWithFormat:@"%d", [[myUsage usersDB] count]];
    
    [[pureController totalBwUsageField] setStringValue:[NSString stringWithFormat:@"%d KB/s", bwUsage]];
    [[pureController sessionInfoField] setStringValue:sessions];
    if ([[NSFileManager defaultManager] fileExistsAtPath:PureFTPPIDFile])
    {
        [[pureController controlServerButton] setTitle:NSLocalizedString(@"Stop",@"localized string")];
        [[pureController serverStatusField] setStringValue:NSLocalizedString(@"pure-ftpd is running ...",@"localized string")];
    }
    else
    {
        [[pureController controlServerButton] setTitle:NSLocalizedString(@"Start",@"localized string")];
        [[pureController serverStatusField] setStringValue:NSLocalizedString(@"pure-ftpd is not running !",@"localized string")];
    }
    

    [[pureController statusOutline] reloadData];
    [[pureController progress] stopAnimation:self];

}

-(void)doQuery
{
    
    [usersArray removeAllObjects];
    
    [myUsage update];
    
    NSMutableDictionary *userInfo;
    NSEnumerator *enumerator = [[myUsage usersDB] objectEnumerator];
    
    while(userInfo = [enumerator nextObject])
    {
        NSMutableDictionary *groupDict;
        groupDict = [self groupWithTitle:[userInfo objectForKey:@"account"]];        
        [self newUserForGroup:groupDict withInfo:userInfo];
    }
    [self updateStatus];
}

-(void)stopQuery
{
   
    if([queryInterval isValid])
        [queryInterval invalidate];
}

-(void)queryWithInterval:(NSTimeInterval)seconds
{
    [self stopQuery];
    [self doQuery];
    queryInterval = [[NSTimer scheduledTimerWithTimeInterval:seconds target:self
                   selector:@selector(doQuery) userInfo:nil repeats:YES] retain];
}


-(NSMutableDictionary *) usersInfo
{
    return [myUsage usersDB];
}


#pragma mark 
#pragma mark #--==> Outline view hacks <==--#
-(NSMutableDictionary *)groupWithTitle:(id)title 
{
    NSEnumerator *usersEnum = [usersArray objectEnumerator];
    NSMutableDictionary *group;
    if ([usersArray count] > 0)
        while (group=[usersEnum nextObject])
            if([[group objectForKey:@"USERNAME"] isEqualToString:title])
                  return group;
     
    group=[NSMutableDictionary dictionary];
    [group setObject:[NSMutableArray array] forKey:@"CHILDREN"];
    if (title) [group setObject:title forKey:@"USERNAME"];
    [usersArray addObject:group];
    
    
    return group;
}

-(NSMutableDictionary *)newUserForGroup:(NSMutableDictionary *)group withInfo:(id)info
{
    NSMutableDictionary *item=[NSMutableDictionary dictionary];
    id children=[group objectForKey:@"CHILDREN"];
    [children addObject:item];
    if (info) [item setObject:info forKey:@"USERINFO"];
    if (group) [item setObject:[WeakReference weakReferenceWithParent:group] forKey:@"PARENT"];
    return item;
}


#pragma mark 
#pragma mark #--==> Outline view datasource <==--#
- (int)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item {
    id children;
    if (!item)
        children=usersArray;
    else
        children=[item objectForKey:@"CHILDREN"];

    return [children count];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item 
{
    id children;
    if (!item)
        children=usersArray;
    else 
        children=[item objectForKey:@"CHILDREN"];
        
    if ((!children) || ([children count]<1)) return NO;
    
    return YES;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(int)index ofItem:(id)item 
{
    id children;
    if (!item)
        children=usersArray;
    else
        children=[item objectForKey:@"CHILDREN"];

    if ((!children) || ([children count]<=index)) return nil;
    
    return [children objectAtIndex:index];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item {
    if ([outlineView levelForItem:item] == nil && [[tableColumn identifier] isEqualToString:@"account"])
        return [item objectForKey:@"USERNAME"];
        
    return [[item objectForKey:@"USERINFO"] objectForKey:[tableColumn identifier]];
}



#pragma mark 
#pragma mark #--==> Outline view delegates <==--#
- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
    NSButton *_closeSessionButton = [pureController closeSessionButton]; 
    if([outlineView levelForItem:item] == nil)
        [_closeSessionButton setEnabled:NO];
    else
        [_closeSessionButton setEnabled:YES];
        
    return YES;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
    if([[pureController statusOutline] selectedRow] == -1)
        [[pureController closeSessionButton] setEnabled:NO];
}

@end
