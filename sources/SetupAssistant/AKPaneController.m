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

#import "AKPaneController.h"

@implementation AKPaneController

- (id) relativeRootView
{
    return relativeRootView_;
}

- (void) loadPaneNib:(NSString *) inNibName withMainController: (id) inMainController
{
    if (!relativeRootView_)
    {
        mainController_ = inMainController;
        
        previousPaneIndex_= -1;
        
        if ([NSBundle loadNibNamed:inNibName owner:self]==NO)
        {
            NSLog(@"A problem occured while loading the nib %@",inNibName);
            NSBeep();
            return;
        }
        
    }
}

- (void) initPaneWithEngine:(id) inEngine
{
    /*
      If you need to set some data to take into account some data obtained from the previous panes
      and saved in the process engine, then overload this method
    */
}

- (NSString *) nextPaneName
{
    return nil;
}

- (void) setPreviousPaneIndex:(int) inPreviousPaneIndex
{
    previousPaneIndex_=inPreviousPaneIndex;
}

- (int) previousPaneIndex
{
    return previousPaneIndex_;
}

- (BOOL) checkPaneValuesWithEngine:(id) inEngine
{
    /*
      Overload this method to be able to stop the navigation to the next pane
      if the values of the current pane are incorrect
    */
    
    return YES;
}

- (void) processWithEngine:(id) inEngine
{
    /*
      Overload this method to process the data provided by the user in this pane
      Don't forget to add the AKProcessEngine subclass header in the code
    */
}

@end
