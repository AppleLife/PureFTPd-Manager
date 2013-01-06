#import <AppKit/NSImage.h>

@interface NSImage (NSImageAdditions)
- (void) drawFlippedInRect:(NSRect) rect operation:(NSCompositingOperation) op fraction:(float) delta;
- (void) drawFlippedInRect:(NSRect) rect operation:(NSCompositingOperation) op;
- (void)applyBadge:(NSImage*)badge withAlpha:(float)alpha scale:(float)scale;
@end
