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

    06/25/03:
        Fix a bug in acceptNewValueInSelectedCell
        
    10/16/04:
        Fix a bug occurring with double-clicks
        Support for proper tabbing
        Support enable/disable state
	
	12/30/04: (2.0b1)
		Fixed a bug with shift-tabbing
		Better detection of number characters
		Support for international localization (12/24 hour mode, leading zeros, etc.)
		Support for optional display of seconds
		Associated stepper is positioned automatically
		Cocoa Bindings support (though buggy)
		
	02/22/05: (2.0b2)
		Fixed main bug with bindings support: initial values now picked up
		Other binding-support improvements
		Created an IBPalette
		Now complies with CodeWarrior 9.4
		Fixed many warnings by CW 9.4 (floor->floorf, casts, etc.)
		Fixed bugs with disabling the control
		Thumb no longer drawn if control is disabled
		Added support for flat appearance of the control (thanks Aaron Brethorst!)
		Guarded +initialize from multiple calls
		Fixed some minor memory leaks
		Cosmetic code cleanup
*/

#import "WBTimeControl.h"

#define WBTC_LEFT_OFFSET		3.5f
#define WBTC_RIGHT_OFFSET		3.0f
#define WBTC_TOP_OFFSET			3.0f
#define WBTC_BOTTOM_OFFSET		9.0f

#ifndef NSAppKitVersionNumber10_3
 #define NSAppKitVersionNumber10_3 743
#endif

// These are absolutes, unchanged by localization
int _WBTimeControlMin[WBTC_MAX_CELL_COUNT]={0,0,0,0};
int _WBTimeControlMax[WBTC_MAX_CELL_COUNT]={23,59,59,1};

// Initial values only, will be set properly in determineTimeFormatInfo
// The hour is the only value that changes with localization
int _WBTimeControlLocalizedMin[WBTC_MAX_CELL_COUNT]={0,0,0,0};
int _WBTimeControlLocalizedMax[WBTC_MAX_CELL_COUNT]={23,59,59,1};

//#define			WBTC_BINDINGS_SUPPORT	(MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_3)
#define			WBTC_BINDINGS_SUPPORT	0

@implementation WBTimeControl

#if WBTC_BINDINGS_SUPPORT
+ (void)initialize
{
	if (self == [WBTimeControl class])
	{
		[self exposeBinding:@"hour"];
		[self exposeBinding:@"minute"];
		[self exposeBinding:@"second"];
		[self exposeBinding:@"date"];
		[self exposeBinding:@"enabled"];

		[self setKeys:[NSArray arrayWithObjects:@"hour", @"minute", @"second", nil]
			triggerChangeNotificationsForDependentKey:@"date"];
	}
}
#endif

- (void)dealloc
{
#if WBTC_BINDINGS_SUPPORT
	[self unbind:@"hour"];
	[self unbind:@"minute"];
	[self unbind:@"second"];
	[self unbind:@"date"];
	[self unbind:@"enabled"];
#endif
    
	[self disposeCells];
	
	[hourFormatStr release]; hourFormatStr = nil;
    [amStr release]; amStr = nil;
    [pmStr release]; pmStr = nil;
    [timeSeparatorStr release]; timeSeparatorStr = nil;
    
    [super dealloc];	
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
	if ([coder allowsKeyedCoding])
	{
		[coder encodeBool:[self showSeconds] forKey:@"showSeconds"];
		[coder encodeBool:[self alignStepper] forKey:@"alignStepper"];
		[coder encodeInt:[self appearance] forKey:@"appearance"];
	}
	else
	{
		BOOL	tempBool;
		int		tempInt;
		tempBool = [self showSeconds];
		[coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempBool = [self alignStepper];
		[coder encodeValueOfObjCType:@encode(BOOL) at:&tempBool];
		tempInt = [self appearance];
		[coder encodeValueOfObjCType:@encode(int) at:&tempInt];
	}
}

#if WBTC_BINDINGS_SUPPORT
- (Class)valueClassForBinding:(NSString *)bindingName
{
    if ([bindingName isEqualToString:@"date"])
	{
		return [NSDate class];	
	}
	else
	{
		return [NSNumber class];
	}
}

- (void)bind:(NSString *)bindingName
    toObject:(id)observableController
 withKeyPath:(NSString *)keyPath
     options:(NSDictionary *)options
{
	int	idx = 0;
    if ([bindingName isEqualToString:@"hour"])
    {
		idx = WBTC_BINDING_HOUR;
	}
	else if ([bindingName isEqualToString:@"minute"])
	{
		idx = WBTC_BINDING_MINUTE;
	}
	else if ([bindingName isEqualToString:@"second"])
	{
		idx = WBTC_BINDING_SECOND;
	}
	else if ([bindingName isEqualToString:@"date"])
	{
		idx = WBTC_BINDING_DATE;
	}
	else if ([bindingName isEqualToString:@"enabled"])
	{
		idx = WBTC_BINDING_ENABLED;
	}

	[observableController addObserver:self
		forKeyPath:keyPath 
		options:nil
		context:(void*)idx];
	
	observedObjects[idx] = [observableController retain];
	observedKeyPaths[idx] = [keyPath copy];

	// So the control (self) can get the initial value
	[self observeValueForKeyPath:keyPath
		ofObject:observableController
		change:nil
		context:(void*)idx];
	
	// Must call super for an IBPalette to work
	[super bind:bindingName
		toObject:observableController
		withKeyPath:keyPath
		options:options];
}

- (void)unbind:(NSString *)bindingName
{
	int	idx = 0;
    if ([bindingName isEqualToString:@"hour"])
    {
		idx = WBTC_BINDING_HOUR;
	}
	else if ([bindingName isEqualToString:@"minute"])
	{
		idx = WBTC_BINDING_MINUTE;
	}
	else if ([bindingName isEqualToString:@"second"])
	{
		idx = WBTC_BINDING_SECOND;
	}
	else if ([bindingName isEqualToString:@"date"])
	{
		idx = WBTC_BINDING_DATE;
	}
	else if ([bindingName isEqualToString:@"enabled"])
	{
		idx = WBTC_BINDING_ENABLED;
	}
	
	[observedObjects[idx] removeObserver:self forKeyPath:observedKeyPaths[idx]];
	[observedObjects[idx] release];
	observedObjects[idx] = nil;

	[observedKeyPaths[idx] release];
	observedKeyPaths[idx] = nil;

	// Must call super for an IBPalette to work
	[super unbind:bindingName];
}

// This is called when the NSController wants to change values
- (void)observeValueForKeyPath:(NSString *)keyPath
	ofObject:(id)object
	change:(NSDictionary *)change
	context:(void *)context
{
    int	idx = (int)context;
	id	newObj = [object valueForKeyPath:keyPath];
	if (idx == WBTC_BINDING_HOUR)
    {
		int	newHour = [newObj intValue];
		[self setHour:newHour];
		[self updateCells];
		[self updateStepperValue];
	}
    else if (idx == WBTC_BINDING_MINUTE)
    {
		int	newMinute = [newObj intValue];
		[self setMinute:newMinute];
		[self updateCells];
		[self updateStepperValue];
	}
    else if (idx == WBTC_BINDING_SECOND)
    {
		int	newSecond = [newObj intValue];
		[self setSecond:newSecond];
		[self updateCells];
		[self updateStepperValue];
	}
    else if (idx == WBTC_BINDING_ENABLED)
    {
		[self setEnabled:[newObj boolValue]];
	}
	
	[self setNeedsDisplay:YES];
}

/*

Need to support NSEditor

- (BOOL)commitEditing
{
}

- (void)discardEditing
{
}
*/

#endif // WBTC_BINDINGS_SUPPORT

- (void)_alignStepper
{
	NSRect tStepperFrame;
	NSRect tFrame;
	
	tFrame=[self frame];
	tStepperFrame=[stepper frame];
	
	tStepperFrame.origin.y=floorf(NSMaxY(tFrame)-(NSHeight(tStepperFrame)-2.0f));
	tStepperFrame.origin.x=floorf(NSMaxX(tFrame)+3.0f);
	
	[stepper setFrame:tStepperFrame];
}

- (void)disposeCells
{
	int i;
	
	for(i=0;i<WBTC_MAX_CELL_COUNT;i++)
	{
		if (cells[i]!=nil)
		{
			[cells[i] release];
			cells[i]=nil;
		}
	}
	
	for(i=0;i<WBTC_MAX_SEPARATOR_COUNT;i++)
	{
		if (colonCells[i]!=nil)
		{
			[colonCells[i] release];
			colonCells[i]=nil;
		}
	}
}

- (void)_interiorDesign
{
	int i;

	// First dispose the cells incase they exist
	
	[self disposeCells];
	
	// Create the cells
        
	cellsCount_=2;
	
	if (flags.showSeconds==YES)
	{
		++cellsCount_;
	}
	
	for(i=0;i<cellsCount_;i++)
	{
		cells[i]=[[NSTextFieldCell alloc] initTextCell:@""];
		[(NSTextFieldCell *) cells[i] setDrawsBackground:YES];
		[(NSTextFieldCell *) cells[i] setEditable:YES];
		[(NSTextFieldCell *) cells[i] setBordered:NO];
		[(NSTextFieldCell *) cells[i] setFont:[NSFont labelFontOfSize:13]];
		[(NSTextFieldCell *) cells[i] setAlignment:NSRightTextAlignment];
	}
	
	if (flags.is24Hour==NO)
	{
		cells[WBTC_AMPM_ID]=[[NSTextFieldCell alloc] initTextCell:@""];
		[(NSTextFieldCell *) cells[WBTC_AMPM_ID] setDrawsBackground:YES];
		[(NSTextFieldCell *) cells[WBTC_AMPM_ID] setEditable:YES];
		[(NSTextFieldCell *) cells[WBTC_AMPM_ID] setBordered:NO];
		[(NSTextFieldCell *) cells[WBTC_AMPM_ID] setFont:[NSFont labelFontOfSize:13]];
		[(NSTextFieldCell *) cells[WBTC_AMPM_ID] setAlignment:NSRightTextAlignment];
	
		cellsCount_++;
	}
	
	// Create the colon cells
	
	colonCellsCount=1;
	
	if (flags.showSeconds==YES)
	{
		++colonCellsCount;
	}
	
	for(i=0;i<colonCellsCount;i++)
	{
		colonCells[i]=[[NSTextFieldCell alloc] initTextCell:timeSeparatorStr];
		[(NSTextFieldCell *) colonCells[i] setDrawsBackground:NO];
		[(NSTextFieldCell *) colonCells[i] setEditable:NO];
		[(NSTextFieldCell *) colonCells[i] setBordered:NO];
		[(NSTextFieldCell *) colonCells[i] setFont:[NSFont labelFontOfSize:13]];
	}
	
	[self sizeToFit];
	[self updateCells];
	
	// Reposition the stepper.  Note: stepper always nil when this
	// method is called from the initializer, but we do this again
	// in awakeFromNib
	if (flags.alignStepper==YES && stepper!=nil)
	{
		[self _alignStepper];
	}
}

- (void)finishInit
{
	// Hour cell selected
	selected=WBTC_HOUR_ID;
	
	flags.isUsingFieldEditor=NO;
	
	// Set the default date, midnight
	[self setHour:0];
	[self setMinute:0];
	[self setSecond:0];
	
	[self setEnabled:YES];

	// Check what the user's date format settings are		
	[self determineTimeFormatInfo];
	
	// Setup the text cells
	[self _interiorDesign];
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [super initWithCoder:coder];
	if (self)
    {
		if ([coder allowsKeyedCoding])
		{
			flags.showSeconds = [coder decodeBoolForKey:@"showSeconds"];
			flags.alignStepper = [coder decodeBoolForKey:@"alignStepper"];
			appearance = [coder decodeIntForKey:@"appearance"];
		}
		else
		{
			BOOL		tempBool;
			[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
			flags.showSeconds = tempBool;
			[coder decodeValueOfObjCType:@encode(BOOL) at:&tempBool];
			flags.alignStepper = tempBool;
			[coder decodeValueOfObjCType:@encode(int) at:&appearance];
		}

		// Init common to frame and coder init
		[self finishInit];
	}
    
    return self;
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
		// Default settings
		flags.showSeconds=YES;
		flags.alignStepper=YES;
		appearance=WBTC_AUTOMATIC_APPEARANCE;

		// Init common to frame and coder init
		[self finishInit];
	}
    
    return self;
}

- (NSDate *)date
{
	NSCalendarDate *	now = [NSCalendarDate calendarDate];
	return [NSCalendarDate dateWithYear:[now yearOfCommonEra]
		month:(unsigned)[now monthOfYear]
		day:(unsigned)[now dayOfMonth]
		hour:(unsigned)[self hour]
		minute:(unsigned)[self minute]
		second:(unsigned)[self second]
		timeZone:[now timeZone]];
}

- (void)setDate:(NSDate *) aDate
{
	NSCalendarDate*		cdate = [aDate dateWithCalendarFormat:nil timeZone:nil];
	[self setHour:[cdate hourOfDay]];
	[self setMinute:[cdate minuteOfHour]];
	[self setSecond:[cdate secondOfMinute]];
}

- (BOOL)showSeconds
{
	return (BOOL)flags.showSeconds;
}

- (void)setShowSeconds:(BOOL) aBoolValue
{
	if (flags.showSeconds!=aBoolValue)
	{
		flags.showSeconds=aBoolValue;
		
		[self _interiorDesign];
		
		[self setNeedsDisplay:YES];
	}
}

- (BOOL)alignStepper
{
	return (BOOL)flags.alignStepper;
}

- (void)setAlignStepper:(BOOL) aBoolValue
{
	if (flags.alignStepper!=aBoolValue)
	{
		flags.alignStepper=aBoolValue;
		
		if (aBoolValue==YES && stepper!=nil)
		{
			[self _alignStepper];
		}
	}
}


- (int)appearance
{
	return appearance;
}

- (void)setAppearance:(int)appearanceType
{
    if (appearance != appearanceType)
    {
        appearance = appearanceType;
    
        [self _interiorDesign];
        
        [self setNeedsDisplay:YES];
    }
}

- (BOOL)isFlatAppearance
{
	return ( (appearance == WBTC_FLAT_APPEARANCE) ||
		( (appearance == WBTC_AUTOMATIC_APPEARANCE) && (floor(NSAppKitVersionNumber) >= NSAppKitVersionNumber10_3) ) );
}

#pragma mark -

- (void)setEnabled:(BOOL) enabled
{
    if ([self isEnabled]!=enabled)
    {
        int i;
        
        if (enabled==NO)
        {
            if (flags.isUsingFieldEditor==YES)
            {
                [cells[selected] endEditing:[self currentEditor]];
            }
        }
    
        for(i=0;i<WBTC_MAX_CELL_COUNT;i++)
        {
            if (cells[i] !=nil)
            {
                [cells[i] setEnabled:enabled];
            }
        }
    
        if (stepper!=nil)
        {
            [stepper setEnabled:enabled];
        }
    
        [super setEnabled:enabled];
    }
}

#pragma mark -

- (void)setDelegate:(id) aDelegate
{
    if (delegate!=nil)
    {
        [[NSNotificationCenter defaultCenter]  removeObserver:delegate
                                                         name:nil
                                                       object:self];
    }
  
    delegate = aDelegate;

    if ([delegate respondsToSelector: @selector(controlTextDidEndEditing:)])
    {
        [[NSNotificationCenter defaultCenter] addObserver: delegate
                                                 selector: @selector(controlTextDidEndEditing:)
                                                     name: NSControlTextDidEndEditingNotification
                                                   object: self];
    
    }
}

#pragma mark -


- (void)updateCells
{
	if (flags.isUsingFieldEditor==YES)
	{
		NSString *	str = nil;
		switch ([self selected])
		{
			case WBTC_HOUR_ID:
				str = [self hourString:[self hour]];				
				break;
			case WBTC_MINUTE_ID:
				str = [self minuteString:[self minute]];
				break;
			case WBTC_SECOND_ID:
				str = [self secondString:[self second]];
				break;
			case WBTC_AMPM_ID:
				str = ([self hour] < 12) ? amStr : pmStr;
				break;
		}

		[[self currentEditor] setString:str];
		[[self currentEditor] selectAll:nil];
	}

	[cells[WBTC_HOUR_ID] setStringValue:[self hourString:[self hour]]];
	[cells[WBTC_MINUTE_ID] setStringValue:[self minuteString:[self minute]]];
	[cells[WBTC_SECOND_ID] setStringValue:[self secondString:[self second]]];
	if ([self hour] < 12)
	{
		[cells[WBTC_AMPM_ID] setStringValue:amStr];
	}
	else
	{
		[cells[WBTC_AMPM_ID] setStringValue:pmStr];
	}
}

#pragma mark -

// These are simple accessor methods giving the hour, minute, and second
// value of the control.  hour is always 0 to 23, despite whatever the
// localised value the control may display

- (void)setHour:(int)aHour
{
    hour = aHour;
    
//    [self updateCells];

// Steph, I'd prefer to keep this as a simple accessor, maybe we should
// override setNeedsDisplay to call updateCells?
}

- (int)hour
{
    return hour;
}

- (void)setMinute:(int)aMinute
{
    minute = aMinute;
}

- (int)minute
{
    return minute;
}

- (void)setSecond:(int)aSecond
{
    second = aSecond;
}

- (int)second
{
    return second;
}

#pragma mark -

- (int)hourToLocalizedHour:(int)aHour
{
	int		val = aHour;
	
	switch (hourType)
	{
		case WBTC_HOUR0TO23:
			val = aHour;
			break;
		
		case WBTC_HOUR1TO12:
			if (aHour > 12)
			{
				val = (aHour-12);
			}
			else if (aHour == 0)
			{
				val = 12;
			}
			else
			{
				val = aHour;
			}
			break;

		case WBTC_HOUR0TO11:
			if (aHour > 11)
			{
				val = (aHour-12);
			}
			else
			{
				val = aHour;
			}
			break;
	}

	return val;
}

- (int)localizedHourToHour:(int)aHour forMeridian:(BOOL)isPM
{
	int		val = aHour;
	
	switch (hourType)
	{
		case WBTC_HOUR0TO23:
			val = aHour;
			break;
		
		case WBTC_HOUR1TO12:
			val = aHour;
			if (isPM)
			{
				if (val!=12)
				{
					val+=12;
				}
			}
			else
			{
				if (val==12)
				{
					val=0;
				}
			}
			break;

		case WBTC_HOUR0TO11:
			val = aHour;
			if (isPM)
			{
				val += 12;
			}
			break;
	}

	return val;
}

#pragma mark -

- (int)selected
{
    return selected;
}

- (void)setSelected:(int)aSelected
{
    if (selected!=aSelected)
	{
		selected=aSelected;
		[self updateStepperValue];
		[self setNeedsDisplay:YES];
	}
}

- (void)updateStepperValue
{
    if (stepper!=nil)
    {
        [stepper setMinValue:(double)_WBTimeControlMin[selected]];
        [stepper setMaxValue:(double)_WBTimeControlMax[selected]];
        
        switch([self selected])
        {
            case WBTC_HOUR_ID:
                [stepper setIntValue:[self hour]];
                break;
            case WBTC_MINUTE_ID:
                [stepper setIntValue:[self minute]];
                break;
            case WBTC_SECOND_ID:
                [stepper setIntValue:[self second]];
                break;
            case WBTC_AMPM_ID:
            	// 0 for AM (0-11), 1 for PM (12-23)
           		[stepper setIntValue:([self hour] >= 12)];
                break;
        }
        
        stepperMidValue=[stepper doubleValue];
    }
}

- (void)awakeFromNib
{
    [self setSelected:WBTC_HOUR_ID];

	// Now that the outlets are connected, reposition the stepper
	if ([self alignStepper]==YES && stepper!=nil)
	{
		[self _alignStepper];
	}
}

- (BOOL)isOpaque
{
    return NO;
}

- (void)drawRect:(NSRect) aFrame
{
    int i;
    NSRect tBounds=[self bounds];
    NSRect tRect;
    float savedLineWidth;
    
    [[NSColor whiteColor] set];

    // Draw the background
    
    tRect=tBounds;
    
	
    if ([self isFlatAppearance])
    {
        tRect.origin.y=WBTC_BOTTOM_OFFSET-1.0f;
        
        tRect.size.height-=(NSMinY(tRect)+2.0f);
    }
    else
    {
        tRect.origin.y=WBTC_BOTTOM_OFFSET-3.0f;
    
        tRect.size.height-=NSMinY(tRect);
    }
    
	//tRect.size.width = floorf(tRect.size.width);
	
    NSRectFill(tRect);
    
    // Draw the Frame
    
    if ([self isFlatAppearance])
		[self drawFlatBorder:tRect];
	else
		[self drawBorder:tRect];
    
    // Draw the selection thumb
    
    if ([self isEnabled])
    {
	    [[NSColor colorWithDeviceWhite:0.5765f alpha:1.0f] set];
	    
	    savedLineWidth=[NSBezierPath defaultLineWidth];
	    
	    [NSBezierPath setDefaultLineWidth:2.0f];
	    
	    [NSBezierPath strokeLineFromPoint:NSMakePoint(floorf(NSMidX(rects[selected]))-4.0f,WBTC_BOTTOM_OFFSET-8.0f) 
	                              toPoint:NSMakePoint(floorf(NSMidX(rects[selected])),WBTC_BOTTOM_OFFSET-4.0f)];
	    [NSBezierPath strokeLineFromPoint:NSMakePoint(floorf(NSMidX(rects[selected])),WBTC_BOTTOM_OFFSET-4.0f)
	                              toPoint:NSMakePoint(floorf(NSMidX(rects[selected]))+4.0f,WBTC_BOTTOM_OFFSET-8.0f)];
	    
	    [NSBezierPath setDefaultLineWidth:savedLineWidth];
	}
	    
    // Draw the Time Separator
    
    for(i=0;i<WBTC_MAX_SEPARATOR_COUNT;i++)
    {
        if (colonCells[i]!=nil)
		{
			[colonCells[i] drawWithFrame:colonRects[i] inView:self];
		}
	}
    
    // Draw the cells
    
    for(i=0;i<WBTC_MAX_CELL_COUNT;i++)
    {
        if (cells[i]!=nil)
		{
			[cells[i] drawWithFrame:rects[i] inView:self];
		}
	}
}

- (void)drawFlatBorder:(NSRect) tRect
{
	NSColor *border = [NSColor colorWithCalibratedRed:(158.0f/255.0f) green:(158.0f/255.0f) blue:(158.0f/255.0f) alpha:1.0f];		
	
	[border set];
	
	NSFrameRect(tRect);
}

- (void)drawBorder:(NSRect) tRect
{
	[[NSColor colorWithDeviceWhite:0.3333f alpha:1.0f] set];
    
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(tRect)+0.5f,NSMinY(tRect)+1.0f) 
                              toPoint:NSMakePoint(NSMinX(tRect)+0.5f,NSMaxY(tRect))];
    
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(tRect),NSMaxY(tRect)-0.5f)
                              toPoint:NSMakePoint(NSMaxX(tRect),NSMaxY(tRect)-0.5f)];
    
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(tRect)+1.5f,NSMinY(tRect)+2.0f) 
                              toPoint:NSMakePoint(NSMinX(tRect)+1.5f,NSMaxY(tRect)-1.0f)];
    
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(tRect)+1.0f,NSMaxY(tRect)-1.5f)
                              toPoint:NSMakePoint(NSMaxX(tRect)-1.0f,NSMaxY(tRect)-1.5f)];
    
    [[NSColor colorWithDeviceWhite:0.6667f alpha:1.0f] set];
    
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(tRect)+1.0f,NSMinY(tRect)+1.5f) 
                              toPoint:NSMakePoint(NSMaxX(tRect)-1.0f,NSMinY(tRect)+1.5f)];
    
    [NSBezierPath strokeLineFromPoint:NSMakePoint(NSMaxX(tRect)-1.5f,NSMinY(tRect)+1.0f) 
                              toPoint:NSMakePoint(NSMaxX(tRect)-1.5f,NSMaxY(tRect)-2.0f)];
}

- (void)mouseDown:(NSEvent *) theEvent
{
    if ([self isEnabled]==YES)
    {
        int i;
        NSPoint tMouseLoc=[self convertPoint:[theEvent locationInWindow] fromView:nil];
        NSRect tThumbRect;
        NSRect tBounds;
        
        // Find where the event occurred
        
        tBounds=[self bounds];
        
        // Either in the thumb part
        
        for(i=0;i<WBTC_MAX_CELL_COUNT;i++)
        {
            if (cells[i]!=nil)
            {
                tThumbRect=rects[i];
                tThumbRect.origin.x-=NSWidth(colonRects[0])*0.5f;
                tThumbRect.origin.y=0.0f;
                tThumbRect.size.width+=NSWidth(colonRects[0]);
                tThumbRect.size.height=WBTC_BOTTOM_OFFSET;
                
                if (NSMouseInRect(tMouseLoc,tThumbRect,[self isFlipped])==YES)
                {
                    if (i==selected)
                    {
                        flags.notReallyTheEnd=YES;
                    }
                    
                    if (flags.isUsingFieldEditor==YES)
                    {
                        [self editOff];
                    }
                    
                    [self editCell:i];
                    
                    return;
                }
            }
        }
        
        // Or in a cell
        
        for(i=0;i<WBTC_MAX_CELL_COUNT;i++)
        {
            if (cells[i]!=nil)
			{
				if (NSMouseInRect(tMouseLoc,rects[i],[self isFlipped])==YES)
				{
					if (i!=selected || flags.isUsingFieldEditor==NO)
					{
						if (flags.isUsingFieldEditor==YES)
						{
							[self editOff];
						}
						else
						{
							[[self window] endEditingFor:nil];
						
							[[self window] makeFirstResponder: self];
						}
				
						[self editCell:i];
					}
					else
					{
						if (flags.isUsingFieldEditor==NO)
						{
							[cells[selected] editWithFrame:rects[selected]
													inView:self
													editor:[self currentEditor]
												  delegate:self
													 event:theEvent];
						}
					}
					
					break;
				}
			}
		}
    }
}

- (BOOL)acceptNewValueInSelectedCell:(id) sender
{
	NSString *string;
    int tValue;
	
    string = [[[[self currentEditor] string] copy] autorelease];

	int		selectedCell = [self selected];
    if (selectedCell<WBTC_AMPM_ID)
	{
		tValue=[string intValue];
		
		if ((tValue>=_WBTimeControlLocalizedMin[selectedCell]) && (tValue<=_WBTimeControlLocalizedMax[selectedCell]))
		{
			// Adjust the localized hour the user has entered into the 24 hour system
			if (selectedCell == WBTC_HOUR_ID)
			{
				BOOL	isPM = ([[cells[WBTC_AMPM_ID] stringValue] isEqualToString:pmStr]==YES);
				tValue = [self localizedHourToHour:tValue forMeridian:isPM];
			}

			// Set the new date			
#if WBTC_BINDINGS_SUPPORT
			if (observedObjects[selectedCell])
			{
				[observedObjects[selectedCell] setValue: [NSNumber numberWithInt:tValue]
					forKeyPath: observedKeyPaths[selectedCell]];
			}
			else
#endif
			{
				switch(selectedCell)
				{
					case WBTC_HOUR_ID:
						[self setHour:tValue];
						break;
					case WBTC_MINUTE_ID:
						[self setMinute:tValue];
						break;
					case WBTC_SECOND_ID:
						[self setSecond:tValue];
						break;
				}
				[self updateCells];
			}
			
			return YES;
		}
	}
	else if (selectedCell==WBTC_AMPM_ID)
	{
		BOOL	isPM = [string isEqualToString:pmStr];
		tValue = [cells[WBTC_HOUR_ID] intValue];
		tValue = [self localizedHourToHour:tValue forMeridian:isPM];
#if WBTC_BINDINGS_SUPPORT
		if (observedObjects[WBTC_HOUR_ID])
		{
			[observedObjects[WBTC_HOUR_ID] setValue: [NSNumber numberWithInt:tValue]
				forKeyPath: observedKeyPaths[WBTC_HOUR_ID]];
		}
		else
#endif
		{
			[self setHour:tValue];
			[self updateCells];
		}

		return YES;
	}
	
    return NO;
}

- (void)editCell:(int) aSelected
{
    NSText *	tObject;
    NSText *	t = [[self window] fieldEditor: YES forObject: self];
    int length;
    id tCell=cells[aSelected];
    
    length = (int)[[tCell stringValue] length];
    
    tObject = [tCell setUpFieldEditorAttributes: t];
    
    [tCell selectWithFrame: rects[aSelected]
                    inView: self
                    editor: tObject
                  delegate: self
                     start: 0
                    length: length];
    
    flags.isUsingFieldEditor=YES;
    
    [self setSelected:aSelected];
}

- (void)editOff
{
    if (flags.isUsingFieldEditor==YES)
    {
        [cells[[self selected]] endEditing: [self currentEditor]];
    
        flags.isUsingFieldEditor=NO;
    }
}

- (void)textDidEndEditing:(NSNotification *) aNotification
{
    NSMutableDictionary * tDictionary;
    id textMovement;
    BOOL wasAccepted;
    int i;
	
    wasAccepted=[self acceptNewValueInSelectedCell:self];
    
    [cells[selected] endEditing: [aNotification object]];

    if (wasAccepted==YES && flags.notReallyTheEnd==NO)
    {
        tDictionary = [[[NSMutableDictionary alloc] initWithDictionary:[aNotification userInfo]] autorelease];
    
        [tDictionary setObject: [aNotification object] forKey: @"NSFieldEditor"];
        
        [[NSNotificationCenter defaultCenter] postNotificationName: NSControlTextDidEndEditingNotification
                                                            object: self
                                                          userInfo: tDictionary];
    }
    
    flags.isUsingFieldEditor=NO;
    flags.notReallyTheEnd=NO;
    
    textMovement = [[aNotification userInfo] objectForKey: @"NSTextMovement"];
    
    if (textMovement)
    {
        switch ([(NSNumber *)textMovement intValue])
        {
            case NSReturnTextMovement:
                if ([self sendAction:[self action] to:[self target]] == NO)
                {
                    NSEvent *event = [[self window] currentEvent];
        
                    if ([self performKeyEquivalent: event] == NO
                        && [[self window] performKeyEquivalent: event] == NO)
                    {
                        
                    }
                }
                break;
            case NSTabTextMovement:
                
				for(i=selected+1;i<WBTC_MAX_CELL_COUNT;i++)
				{
					if (cells[i]!=nil)
					{
						[self editCell:i];
						return;
					}
				}
                
                [[self window] selectKeyViewFollowingView: self];
                
                if ([[self window] firstResponder] == [self window])
                {
                    [self editCell:WBTC_HOUR_ID];
                }
                break;
            case NSBacktabTextMovement:
                
				for(i=selected-1;i>=0;i--)
				{
					if (cells[i]!=nil)
					{
						[self editCell:i];
						return;
					}
				}
                
                [[self window] selectKeyViewPrecedingView: self];
        
                if ([[self window] firstResponder] == [self window])
                {
                    for(i=WBTC_MAX_CELL_COUNT-1;i>=0;i--)
					{
						if (cells[i]!=nil)
						{
							[self editCell:i];
							return;
						}
					}
                }
                break;
        }
    }
}

- (BOOL)textView:(NSTextView *)textView shouldChangeTextInRange:(NSRange)affectedCharRange replacementString:(NSString *)replacementString
{
	if (selected==WBTC_AMPM_ID)
	{
		// Note: This code fails if the am and pm str start with the same char
		// this is unlikely I guess, but possible
		
		unichar tFirstChar;
		
		tFirstChar=[[replacementString lowercaseString] characterAtIndex:0];
		
		if (tFirstChar==[[amStr lowercaseString] characterAtIndex:0])
		{
			if ([self hour]>=12)
			{
				[textView setString:amStr];
				[textView selectAll:nil];
				
				[self setHour:[self hour]-12];
			}
		}
		else if (tFirstChar==[[pmStr lowercaseString] characterAtIndex:0])
		{
			if ([self hour]<12)
			{
				[textView setString:pmStr];
				[textView selectAll:nil];
				
				[self setHour:[self hour]+12];
			}
		}
		
		return NO;
	}
	else
	{
		// For the hour, minute, and second, reject if the string is more than 2
		// characters.  This has a nice UI effect too, of stopping the string from wrapping
		if (affectedCharRange.location>=2 || affectedCharRange.length>2)
		{
			return NO;
		}

		// Create a new string the same as replacementString but with no numbers,
		// if the string is non-empty, then it's no good
		NSString*	trimmedStr = [replacementString stringByTrimmingCharactersInSet:[NSCharacterSet decimalDigitCharacterSet]];
		
		if ([trimmedStr length] != 0)
		{
			return NO;
		}
    }
	
    if (stepper!=nil)
    {
        NSMutableString * tString;
        int tValue;
        
        tString=[[[textView string] mutableCopy] autorelease];
        
        [tString replaceCharactersInRange:affectedCharRange withString:replacementString];
        
        tValue=[tString intValue];
        
        if ((tValue<_WBTimeControlMin[selected]) || (tValue>_WBTimeControlMax[selected]))
        {
            [stepper setDoubleValue:stepperMidValue];
        }
        else
        {
            [stepper setIntValue:tValue];
        }

    }
    
    return YES;
}

- (BOOL)acceptsFirstResponder
{
    // We want to be able to become first responder
    return [self isEnabled];
}

- (BOOL)needsPanelToBecomeKey
{
    // We want to get focus via mouse down AND tabbing
    
    return YES;
}

- (BOOL)becomeFirstResponder
{
    BOOL result = [super becomeFirstResponder];

    if (result)
    {
        NSSelectionDirection selectionDirection = [[self window] keyViewSelectionDirection];
        if (selectionDirection==NSSelectingNext)
        {
            // Select the first cell, the hour cell (it is always present)
			[self editCell:WBTC_HOUR_ID];
        }
        else if (selectionDirection==NSSelectingPrevious)
        {
			// Select the last cell, it may be the am/pm cell, the second cell, or
			// the minute cell
			int i;
			for (i = WBTC_MAX_CELL_COUNT-1; i >= 0; i--)
			{
				if (cells[i] != nil)
				{
					[self editCell:i];
					break;
				}
			}
		}
        else
        {
            // Direct selection by clicking.  Let the mouse down code figure out which cell to edit.
		}
    }
    
    return result;
}

- (void)determineTimeFormatInfo
{
	NSUserDefaults *	sud = [NSUserDefaults standardUserDefaults];

	// Assume 2 digits for the hour, unless we find %1I, %1i, or %1H in the time format string
	NSString *			tfs = [sud stringForKey:NSTimeFormatString];
	NSRange				range1 = [tfs rangeOfString:@"%1I" options:NSCaseInsensitiveSearch];
	NSRange				range2 = [tfs rangeOfString:@"%1H"];
	
	if ((range1.length == 0) && (range2.length == 0))
	{
		hourFormatStr = @"%02d";
	}
	else
	{
		hourFormatStr = @"%01d";
	}
	[hourFormatStr retain];
	
	// Get the strings for AM and PM
	NSArray *		ampm = [sud stringArrayForKey:NSAMPMDesignation];
	amStr = [[ampm objectAtIndex:0] retain];
	pmStr = [[ampm objectAtIndex:1] retain];
	
	// Check if we are using 24 hour mode (as opposed to 12 hour, ie AM/PM)
	NSRange			range3 = [tfs rangeOfString:@"%H"];
	flags.is24Hour = (range2.length != 0) || (range3.length != 0);
	
	// Get the time separator character
	// The encoding of data retrieved from the intl* resources can be 
	// determined by using GetScriptManagerVariable(smSysScript) and then 
	// calling UpgradeScriptInfoToTextEncoding on the result. You can then 
	// convert it to a CFString using that encoding.
	Intl0Hndl		intl0 = (Intl0Hndl)GetIntlResource (0);
	unsigned char	timeSep = (unsigned char)((*intl0)->timeSep);
	long			smv = GetScriptManagerVariable (smSysScript);
	TextEncoding	textEnc;
	OSStatus		err = UpgradeScriptInfoToTextEncoding (
		(ScriptCode)smv,		// ScriptCode
		kTextLanguageDontCare,	// LangCode
		kTextRegionDontCare,	// RegionCode
		NULL,					// ConstStr255Param
		&textEnc);				// TextEncoding
	if (err) {
		textEnc = kCFStringEncodingMacRoman;
	}

	timeSeparatorStr = (NSString *)CFStringCreateWithBytes (
		kCFAllocatorDefault,
		&timeSep,	// bytes
		1,			// length
		textEnc,	// CFStringEncoding encoding
		false);		// isExternalRepresentation);

	// Decide permissible ranges for the hour
	if (flags.is24Hour)
	{
		_WBTimeControlLocalizedMin[WBTC_HOUR_ID] = 0;
		_WBTimeControlLocalizedMax[WBTC_HOUR_ID] = 23;
		hourType = WBTC_HOUR0TO23;
	}
	else
	{
		// Upperacse 'I' means 1-12, lowercase 'i' means 0-11
		NSRange				range4 = [tfs rangeOfString:@"%1I"];
		NSRange				range5 = [tfs rangeOfString:@"%I"];

		if ((range4.length != 0) || (range5.length != 0))
		{
			_WBTimeControlLocalizedMin[WBTC_HOUR_ID] = 1;
			_WBTimeControlLocalizedMax[WBTC_HOUR_ID] = 12;
			hourType = WBTC_HOUR1TO12;
		}
		else
		{
			_WBTimeControlLocalizedMin[WBTC_HOUR_ID] = 0;
			_WBTimeControlLocalizedMax[WBTC_HOUR_ID] = 11;
			hourType = WBTC_HOUR0TO11;
		}
	}
}

// These 3 methods return localized strings, that is: with or without
// leading zeros, as 12 hour or 24 hour, etc.

- (NSString *)hourString:(int)aHour
{
	int tHour = [self hourToLocalizedHour: aHour];
	return [NSString stringWithFormat:hourFormatStr, tHour];
}

- (NSString *)minuteString:(int)aMinute
{
	// minutes and seconds are always exactly 2 digits
	return [NSString stringWithFormat:@"%02d", aMinute];
}

- (NSString *)secondString:(int)aSecond
{
	// minutes and seconds are always exactly 2 digits
	return [NSString stringWithFormat:@"%02d", aSecond];
}

- (void)sizeToFit
{
	NSRect tIdealRect;
	NSSize tSize;
	NSSize tFinalSize=NSZeroSize;
	NSSize tSeparatorSize;
	NSSize tAMPMSize;
	int i;
	NSTextFieldCell * tCell;
	NSRect tCellFrame;
	
	tCell=[[NSTextFieldCell alloc] initTextCell:@"99"];
	[tCell setDrawsBackground:YES];
	[tCell setEditable:YES];
	[tCell setBordered:NO];
	[tCell setFont:[NSFont labelFontOfSize:13]];
	[tCell setAlignment:NSRightTextAlignment];
	
	// Compute Width and height for the hour cell
		
	tSize=[tCell cellSize];

	if ([self isFlatAppearance]==NO)
	{
		tFinalSize.width+=WBTC_LEFT_OFFSET+WBTC_RIGHT_OFFSET;	
    }
	else
	{
		tFinalSize.width+=WBTC_LEFT_OFFSET;
	}
	
	tFinalSize.height+=WBTC_TOP_OFFSET+WBTC_BOTTOM_OFFSET;
    
    tFinalSize.height+=floorf(tSize.height);
	
	tFinalSize.width+=2*tSize.width;
	
	if (flags.showSeconds==YES)
	{
		tFinalSize.width+=tSize.width;
	}
	
	if (flags.is24Hour==NO)
	{
		// Compute AM/PM Size
		
		NSSize tMaxSize;
		
		[tCell setStringValue:amStr];
			
		tMaxSize=[tCell cellSize];
		
		[tCell setStringValue:pmStr];
		
		tAMPMSize=[tCell cellSize];
		
		if (tMaxSize.width>tAMPMSize.width)
		{
			tAMPMSize.width=tMaxSize.width;
		}
			
		tFinalSize.width+=tAMPMSize.width;
	}
	
	[tCell setStringValue:timeSeparatorStr];
			
	tSeparatorSize=[tCell cellSize];
	
	[tCell release];
	
	for(i=0;i<colonCellsCount;i++)
	{
		tFinalSize.width+=tSeparatorSize.width;
	}
	
	// Computes the rect for the various cells
	
	// Hour, separator, minute, [separator], [seconds]
	
	tCellFrame.origin.x=WBTC_LEFT_OFFSET;
	
	tCellFrame.origin.y=WBTC_BOTTOM_OFFSET;
		
	tCellFrame.size=tSize;
	
	rects[WBTC_HOUR_ID]=tCellFrame;
	
	tCellFrame.origin.x=floorf(NSMaxX(tCellFrame))-0.5f;
	tCellFrame.size=tSeparatorSize;
	
	colonRects[WBTC_HOUR_ID]=tCellFrame;
	
	tCellFrame.origin.x=floorf(NSMaxX(tCellFrame))-0.5f;
	tCellFrame.size=tSize;
	
	rects[WBTC_MINUTE_ID]=tCellFrame;
	
	if (flags.showSeconds==YES)
	{
		tCellFrame.origin.x=floorf(NSMaxX(tCellFrame))-0.5f;
		tCellFrame.size=tSeparatorSize;
		
		colonRects[WBTC_MINUTE_ID]=tCellFrame;
		
		tCellFrame.origin.x=floorf(NSMaxX(tCellFrame)-0.5f);
		tCellFrame.size=tSize;
		
		rects[WBTC_SECOND_ID]=tCellFrame;
	}
	
	// [AMP/PM]
	
	if (flags.is24Hour==NO)
	{
		tCellFrame.origin.x=floorf(NSMaxX(tCellFrame))-0.5f;
		tCellFrame.size=tAMPMSize;
		
		rects[WBTC_AMPM_ID]=tCellFrame;
	}
	
	tFinalSize.width=floorf(tFinalSize.width);
	
	tIdealRect.origin=[self frame].origin;
	
	tIdealRect.size=tFinalSize;
	
	[self setFrame:tIdealRect];
}

// handles a click of the associated stepper control
- (IBAction)handleStepperClick:(id)sender
{
    int	tValue = [stepper intValue];

	int	selectedCell = [self selected];
	
	// Fake an am/pm change into an hour change
	if (selectedCell == WBTC_AMPM_ID)
	{
		if (tValue == 0)
		{
			tValue = [self hour]-12;
		}
		else
		{
			tValue = [self hour]+12;
		}
		selectedCell = WBTC_HOUR_ID;
	}
#if WBTC_BINDINGS_SUPPORT
	if (observedObjects[selectedCell])
	{
		[observedObjects[selectedCell] setValue: [NSNumber numberWithInt:tValue]
			forKeyPath: observedKeyPaths[selectedCell]];
	}
	else
#endif
	{
		switch(selectedCell)
		{
			// For the hour cell, the stepper is always 0-23
			case WBTC_HOUR_ID:
				[self setHour:tValue];
				break;
			case WBTC_MINUTE_ID:
				[self setMinute:tValue];
				break;
			case WBTC_SECOND_ID:
				[self setSecond:tValue];
				break;
		}
		[self updateCells];
	}
}

@end
