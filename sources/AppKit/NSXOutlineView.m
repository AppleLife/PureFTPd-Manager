
#import "NSXOutlineView.h"
#define STRIPE_RED   (237.0 / 255.0)
#define STRIPE_GREEN (243.0 / 255.0)
#define STRIPE_BLUE  (254.0 / 255.0)
static NSColor *sStripeColor = nil;

@implementation NSXOutlineView

- (void)setMenuDelegate:(id)new_menu_delegate
{
    _menu_delegate = new_menu_delegate;
}

-(NSMenu*)menuForEvent:(NSEvent*)evt 
{
    /*NSPoint point = [self convertPoint:[evt locationInWindow] fromView:NULL];
    int column = [self columnAtPoint:point];
    int row = [self rowAtPoint:point];
    if ([_menu_delegate respondsToSelector:@selector(tableView:menuForTableColumn:row:)] )
        return [_menu_delegate tableView:self
                      menuForTableColumn:[[self tableColumns] objectAtIndex:column]
                                     row:row];
    else*/ 
    return NULL;
}

- (void)drawRect:(NSRect)aRect
{
    [super drawRect:aRect];
}

- (void) highlightSelectionInClipRect:(NSRect)rect {
    [self drawStripesInRect:rect];
    [super highlightSelectionInClipRect:rect];
}

- (void)drawGridInClipRect:(NSRect)aRect {
    NSRect rect = [self bounds];
    NSArray *columnsArray = [self tableColumns];
    int i, xPos = 0;
    for(i = 0 ; i < [columnsArray count] ; i++) { 
        xPos = xPos + [[columnsArray objectAtIndex:i] width] + [self intercellSpacing].width; 
        [[NSColor colorWithCalibratedWhite:0.0 alpha:0.1] set];
        [NSBezierPath strokeLineFromPoint:NSMakePoint(rect.origin.x - 0.5 + xPos,rect.origin.y)
                                  toPoint:NSMakePoint(rect.origin.x - 0.5 + xPos,rect.size.height)];
    }
}


- (void) drawStripesInRect:(NSRect)clipRect {
    NSRect stripeRect;
    float fullRowHeight = [self rowHeight] + [self intercellSpacing].height;
    float clipBottom = NSMaxY(clipRect);
    int firstStripe = clipRect.origin.y / fullRowHeight;
    if (firstStripe % 2 == 0)
        firstStripe++;			
    
    stripeRect.origin.x = clipRect.origin.x;
    stripeRect.origin.y = firstStripe * fullRowHeight;
    stripeRect.size.width = clipRect.size.width;
    stripeRect.size.height = fullRowHeight;
    if (sStripeColor == nil)
        sStripeColor = [[NSColor colorWithCalibratedRed:STRIPE_RED green:STRIPE_GREEN blue:STRIPE_BLUE alpha:1.0] retain];
    [sStripeColor set];
    while (stripeRect.origin.y < clipBottom) {
        NSRectFill(stripeRect);
        stripeRect.origin.y += fullRowHeight * 2.0;
    }
}

@end
