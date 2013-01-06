/*
    Redistribution and use in source and binary forms, with or without modification,
    are permitted provided that the following conditions are met:

	Redistributions of source code must retain this list of conditions and the following disclaimer.

	The names of its contributors may not be used to endorse or promote products derived from this
    software without specific prior written permission.

	THIS SOFTWARE IS PROVIDED BY THE CONTRIBUTORS "AS IS" AND ANY 
    EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES 
    OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT 
    SHALL THE CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, 
    SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT 
    OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
    HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, 
    OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS 
    SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import <AppKit/AppKit.h>

#define NSXTIMECONTROL_CELL_COUNT		2

#define NSXTIMECONTROL_HOUR_ID			0
#define NSXTIMECONTROL_MINUTE_ID			1
#define NSXTIMECONTROL_SECOND_ID			2

@interface NSXTimeControl : NSControl
{
    NSCalendarDate *		currentDate;
    
    NSCell *				cells[NSXTIMECONTROL_CELL_COUNT];
    NSRect 					rects[NSXTIMECONTROL_CELL_COUNT];
    
    NSCell *				colonCells[NSXTIMECONTROL_CELL_COUNT-1];
    NSRect 					colonRects[NSXTIMECONTROL_CELL_COUNT-1];
    
    int 					selected;
    
    IBOutlet id 			delegate;
    
    BOOL 					isUsingFieldEditor;
    
    IBOutlet NSStepper *	stepper;
    double 					stepperMidValue;
}




- (id) date;
- (void) setDate:(id) aDate;

- (NSStepper *) stepper;

- (void) setDelegate:(id) aDelegate;

- (void) editCell:(int) aSelected;
- (void )editOff;

- (int) selected;
- (void) setSelected:(int)aSelected;

- (void) setHour:(int)aHour;
- (int) hour;

- (void) setMinute:(int)aMinute;
- (int) minute;

- (void) setSecond:(int)aSecond;
- (int) second;

- (BOOL) acceptNewValueInSelectedCell:(id) sender;

@end