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

/* All constants are private */
#define WBTC_MAX_CELL_COUNT				4
#define WBTC_MAX_SEPARATOR_COUNT		2

#define WBTC_HOUR_ID					0
#define WBTC_MINUTE_ID					1
#define WBTC_SECOND_ID					2
#define WBTC_AMPM_ID					3

#define	WBTC_HOUR0TO23					1
#define	WBTC_HOUR1TO12					2
#define	WBTC_HOUR0TO11					3

#define	WBTC_AUTOMATIC_APPEARANCE		0
#define	WBTC_BEVELED_APPEARANCE			1
#define	WBTC_FLAT_APPEARANCE			2

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
	#define WBTC_BINDING_HOUR			0
	#define WBTC_BINDING_MINUTE			1
	#define WBTC_BINDING_SECOND			2
	#define WBTC_BINDING_DATE			3
	#define WBTC_BINDING_ENABLED		4
	#define WBTC_BINDING_MAX			5
#endif

/* Private structure */
typedef struct {
#ifdef __BIG_ENDIAN__
	unsigned int isUsingFieldEditor:1;
	unsigned int is24Hour:1;
	unsigned int notReallyTheEnd:1;
	unsigned int showSeconds:1;
	unsigned int alignStepper:1;
#else
	unsigned int alignStepper:1;
	unsigned int showSeconds:1;
	unsigned int notReallyTheEnd:1;
	unsigned int is24Hour:1;
	unsigned int isUsingFieldEditor:1;
#endif
} WBTCFlags;
	
@interface WBTimeControl : NSControl
{
    /* All instance variables are private */
	WBTCFlags				flags;
	int						appearance;
	
	int						hour;
	int						minute;
	int						second;
    
    NSCell *				cells[WBTC_MAX_CELL_COUNT];
    NSRect 					rects[WBTC_MAX_CELL_COUNT];
    
    NSCell *				colonCells[WBTC_MAX_SEPARATOR_COUNT];
    NSRect 					colonRects[WBTC_MAX_SEPARATOR_COUNT];
    
	int						colonCellsCount;
	int						cellsCount_;
	
    int 					selected;
    
    IBOutlet id 			delegate;
    
    IBOutlet NSStepper *	stepper;
    double 					stepperMidValue;

	NSString *				hourFormatStr;
	NSString *				amStr;
	NSString *				pmStr;
	NSString *				timeSeparatorStr;
	int						hourType;

#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3
	id						observedObjects[WBTC_BINDING_MAX];
	NSString *				observedKeyPaths[WBTC_BINDING_MAX];
#endif
}

/* public methods */
- (int)hour;
- (void)setHour:(int)aHour;

- (int)minute;
- (void)setMinute:(int)aMinute;

- (int)second;
- (void)setSecond:(int)aSecond;

- (NSDate *)date;
- (void)setDate:(NSDate *)aDate;

- (void)setDelegate:(id)aDelegate;

- (int)appearance;
- (void)setAppearance:(int)flat;

- (int)selected;
- (void)setSelected:(int)aSelected;

- (BOOL)showSeconds;
- (void)setShowSeconds:(BOOL)aBoolValue;

- (BOOL)alignStepper;
- (void)setAlignStepper:(BOOL)aBoolValue;

- (IBAction)handleStepperClick:(id)sender;

/* private! do not use! */
- (void)disposeCells;

- (void)editCell:(int)aSelected;
- (void)editOff;
- (void)updateStepperValue;

- (void)drawFlatBorder:(NSRect)tRect;
- (void)drawBorder:(NSRect)tRect;

- (void)updateCells;

- (int)hourToLocalizedHour:(int)aHour;
- (int)localizedHourToHour:(int)aHour forMeridian:(BOOL)isPM;

- (BOOL)acceptNewValueInSelectedCell:(id)sender;

- (void)determineTimeFormatInfo;
- (NSString *)hourString:(int)aHour;
- (NSString *)minuteString:(int)aMinute;
- (NSString *)secondString:(int)aSecond;

@end