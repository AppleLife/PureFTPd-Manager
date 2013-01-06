/* GraphController */

#import <Cocoa/Cocoa.h>
#import "LogManager.h"
#import <SM2DGraphView/SM2DGraphView.h>

#define SIZETB 0
#define SIZEGB 1
#define SIZEMB 2


@interface GraphController : NSObject
{
    IBOutlet NSPopUpButton *graphYearPop;
    IBOutlet NSPopUpButton *graphMonthPop;
    IBOutlet SM2DGraphView *graphView;
    IBOutlet NSMenu *optionsMenu;
    IBOutlet NSPopUpButton *totalUnits;
    
    
    int cycle;
    int koctet;
    unsigned long moctet;
    unsigned long goctet;
    int sizeUnit;
    
    NSDictionary *userTraffic;
}
+(id) getInstance;
-(void) refreshUserGraphView;
- (BOOL) gatherIndexes;
- (IBAction)changeTotalSize:(id)sender;
@end
