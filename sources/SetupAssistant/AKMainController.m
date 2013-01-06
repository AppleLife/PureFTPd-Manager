/*
    Copyright (c) 2003, Stephane Sudre
	All rights reserved.

	Redistribution and use in source and binary forms, with or without modification, are permitted
    provided that the following conditions are met:

	Redistributions of source code must retain the above copyright notice, this list of conditions
    and the following disclaimer.

	Redistributions in binary form must reproduce the above copyright notice, this list of conditions
    and the following disclaimer in the documentation and/or other materials provided with the distribution.

	Neither the name of the WhiteBox nor the names of its contributors may be used to endorse 
    or promote products derived from this software without specific prior written permission.


	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR
    IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY 
    AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR 
    CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
    DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
    DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
    WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN 
    ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "AKMainController.h"
#import "AKListView.h"

@implementation AKMainController

- (void) awakeFromNib
{
    NSString * tPath;
    int tCount;
    int i;
    NSDictionary * tDictionary;
    
    _terminateNow_=NO;
    
    tPath=[[NSBundle mainBundle] pathForResource:@"InfoAssistant" ofType:@"plist"];
    
    tDictionary=[NSDictionary dictionaryWithContentsOfFile:tPath];
    
    processEngine_=[[NSClassFromString([tDictionary objectForKey:@"ProcessEngine Name"]) alloc] init];
    
    [processEngine_ initPrivilege];
    
    tPath=[[NSBundle mainBundle] pathForResource:@"PaneList" ofType:@"plist"];
    
    infoArray_=[[NSArray arrayWithContentsOfFile:tPath] retain];
    
    tCount=[infoArray_ count];
    
    paneControllerArray_ = [[NSMutableArray arrayWithCapacity:tCount] retain];
    
    for(i=0;i<tCount;i++)
    {
        id tObject;
        id tPaneController;
        
        tObject=[infoArray_ objectAtIndex:i];
        
        tPaneController=[NSClassFromString([tObject objectForKey:@"Class Name"]) alloc];
        [tPaneController loadPaneNib:[tObject objectForKey:@"Nib Name"] withMainController:self];
        
        [IBlist_ addPaneName:NSLocalizedString([tObject objectForKey:@"List Title"],@"No comment")];
        [paneControllerArray_ insertObject:tPaneController atIndex:i];
    }
    
    // Set the Window title
    
    [IBwindow_ setTitle:NSLocalizedString(@"PureFTPd Manager Setup Assistant", @"Title of the window")];
    
    // Set the Image
    
    [IBlogo_ setImage:[NSImage imageNamed:[tDictionary objectForKey:@"Assistant Logo Name"]]];
    
    // A COMPLETER
    
    currentRelativeRootView_=nil;
    
    privilegeNeeded_=[[tDictionary objectForKey:@"Privileges Needed"] isEqualToString:@"YES"];
    
    if (privilegeNeeded_==YES)
    {
        if ([processEngine_ isAuthorized]==YES)
        {
            [self initInterface];
        }
        else
        {
            currentRelativeRootView_=authRelativeRootView_;
            
            [IBbox_ addSubview:authRelativeRootView_];
            [currentRelativeRootView_ setFrameOrigin:NSMakePoint(1,1)];
            
            [IBpreviousSlide_ setEnabled:NO];
            [IBnextSlide_ setEnabled:NO];
        }
    }
    else
    {
        [self initInterface];
    }
    
    [IBwindow_ center];
    [NSApp activateIgnoringOtherApps:YES];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    if (privilegeNeeded_==YES)
    {
        if ([processEngine_ isAuthorized]==NO)
        {
            // Display the authentication dialog
            
            [self authenticate:self];
        }
    }
}

- (void) initInterface
{
    currentPaneIndex_=0;
    currentPaneController_=[self paneControllerAtIndex:currentPaneIndex_];
    
    if (currentPaneController_!=nil)
    {
        currentRelativeRootView_=[currentPaneController_ relativeRootView];
    
        [IBbox_ addSubview:currentRelativeRootView_];
        [currentRelativeRootView_ setFrameOrigin:NSMakePoint(1,1)];
        
        [IBpreviousSlide_ setEnabled:NO];
        [IBnextSlide_ setEnabled:YES];
        [self setPaneTitleForPaneAtIndex:currentPaneIndex_];
        
        [currentPaneController_ initPaneWithEngine:processEngine_];
    }
    else
    {
        NSLog(@"Gross Problem !");
    }
}

- (IBAction)authenticate:(id)sender
{
    if ([processEngine_ privilegeCheck]==YES)
    {
        [currentRelativeRootView_ removeFromSuperview];
        
        [self initInterface];
    }
}

- (BOOL) windowShouldClose:(id) sender
{
    BOOL tShouldClose=YES;
    
    if (NSRunAlertPanel(NSLocalizedString(@"Do you really want to quit PureFTPd Manager Setup Assistant ?",@"Quit Alert Message"),@"",
                        NSLocalizedString(@"Continue",@"Continue"),
                        NSLocalizedString(@"Quit",@"Quit"),nil)==NSAlertDefaultReturn)
    {
        tShouldClose=NO;
    }
    else
    {
        _terminateNow_=YES;
        [NSApp terminate:self];
    }

    return tShouldClose;
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
    NSApplicationTerminateReply tShouldClose=NSTerminateNow;
    
    if (_terminateNow_==NO)
    {
        if (NSRunAlertPanel(NSLocalizedString(@"Do you really want to quit PureFTPd Manager Setup Assistant ?",@"Quit Alert Message"),@"",
                            NSLocalizedString(@"Continue",@"Continue"),
                            NSLocalizedString(@"Quit",@"Quit"),nil)==NSAlertDefaultReturn)
        {
            tShouldClose=NSTerminateCancel;
        }
    }
    
    if (tShouldClose==NSTerminateNow)
    {
        [processEngine_ removePrivilege];
    }
    
    return tShouldClose;
}


- (AKPaneController *) paneControllerAtIndex:(int) inIndex
{
    int tArrayCount=[paneControllerArray_ count];
    
    if (inIndex>=0 && inIndex<tArrayCount)
    {
        return [paneControllerArray_ objectAtIndex:inIndex];
    }
    
    return nil;
}

- (int) indexOfPaneControllerWithName:(NSString *) inName
{
    int tArrayCount=[paneControllerArray_ count];
    int i;
    
    for(i=0;i<tArrayCount;i++)
    {
        if ([[[infoArray_ objectAtIndex:i] objectForKey:@"List Title"] isEqualToString:inName]==YES)
        {
            return i;
        }
    }
    
    return -1;
}

- (void) setPaneTitleForPaneAtIndex:(int) inIndex
{
    if (inIndex>=0 && inIndex<[infoArray_ count])
    {
        [IBpaneTitle_ setStringValue:NSLocalizedString([[infoArray_ objectAtIndex:inIndex] objectForKey:@"Pane Title"],@"No comment")];
    }
}

- (IBAction)finishSetUp:(id)sender
{
    [processEngine_ startProcess];
    
    [self processPaneController:currentPaneController_ withEngine:processEngine_];
    
    if ([processEngine_ endProcess]==YES)
    {
        [processEngine_ removePrivilege];
        
        _terminateNow_=YES;
        [NSApp terminate:self];
    }
}

/* Recursive process to start with the first pane */

- (void) processPaneController:(AKPaneController *) inPaneController withEngine:(id) inEngine
{
    AKPaneController * tPaneController;
    unsigned long tIndex;
    
    tIndex=[inPaneController previousPaneIndex];
    
    if (tIndex>0)
    {
        tPaneController = [self paneControllerAtIndex:tIndex];
        
        if (tPaneController!=nil)
        {
            [self processPaneController:tPaneController withEngine:inEngine];
        }
    }

    [inPaneController processWithEngine:inEngine];
}

- (IBAction)nextSlide:(id)sender
{
    if ([currentPaneController_ checkPaneValuesWithEngine:processEngine_]==YES)
    {
        AKPaneController * tPaneController;
        int tIndex;
        NSString * tNextPaneName;
        
        tNextPaneName=[currentPaneController_ nextPaneName];
        
        if (tNextPaneName!=nil)
        {
            tIndex=[self indexOfPaneControllerWithName:tNextPaneName];
        }
        else
        {
            tIndex=currentPaneIndex_+1;
        }
        
        tPaneController = [self paneControllerAtIndex:tIndex];
        
        if (tPaneController!=nil)
        {
            // Set up the new content of the box
            
            [currentRelativeRootView_ removeFromSuperview];
            
            [IBbox_  addSubview:[tPaneController relativeRootView]];
            
            currentRelativeRootView_=[tPaneController relativeRootView];
            [currentRelativeRootView_ setFrameOrigin:NSMakePoint(1,1)];
        }
        else
        {
            NSLog(@"The next pane was not found");
            return;
        }
        
        if (currentPaneIndex_==0)
        {
            [IBpreviousSlide_ setEnabled:YES];
        }
        
        [tPaneController setPreviousPaneIndex:currentPaneIndex_];
        
        currentPaneIndex_=tIndex;
        currentPaneController_=tPaneController;
        [self setPaneTitleForPaneAtIndex:tIndex];
        
        if (currentPaneIndex_==([infoArray_ count] -1))
        {
            [IBnextSlide_ setEnabled:NO];
        }
        
        // Update the list View
    
        [IBlist_ setCurrentPaneIndex:currentPaneIndex_];
        
        [currentPaneController_ initPaneWithEngine:processEngine_];
    }
}

- (IBAction)previousSlide:(id)sender
{
    AKPaneController * tPaneController;
    int tIndex;
    
    tIndex=[currentPaneController_ previousPaneIndex];
    
    if (tIndex==-1)
    {
        NSLog(@"No previous pane is defined for this pane");
        return;
    }
        
    tPaneController = [self paneControllerAtIndex:tIndex];
    
    if (tPaneController!=nil)
    {
        // Set up the new content of the box
        
        [currentRelativeRootView_ removeFromSuperview];
        
        [IBbox_  addSubview:[tPaneController relativeRootView]];
        
        currentRelativeRootView_=[tPaneController relativeRootView];
        [currentRelativeRootView_ setFrameOrigin:NSMakePoint(1,1)];
    }
    else
    {
        NSLog(@"The previous pane was not found");
        return;
    }
    
    if (currentPaneIndex_==([infoArray_ count] -1))
    {
        [IBnextSlide_ setEnabled:YES];
    }
    
    currentPaneIndex_=tIndex;
    currentPaneController_=tPaneController;
    [self setPaneTitleForPaneAtIndex:tIndex];
    
    
    if (currentPaneIndex_==0)
    {
        [IBpreviousSlide_ setEnabled:NO];
    }
    
    // Update the list View
    
    [IBlist_ setCurrentPaneIndex:currentPaneIndex_];
}

@end
