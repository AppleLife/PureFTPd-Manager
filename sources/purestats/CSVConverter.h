//
//  CSVConverter.h
//  PureFTP
//
//  Created by Jean-Matthieu Schaffhauser on 14/03/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "defines.h"

@interface CSVConverter : NSObject {
	NSString *currentUser;
    
    NSMutableDictionary *FTPStats;
    NSMutableDictionary *webpages;
}

- (void)updateFTPStats;
- (void)convertToCSV;
- (void)createUserStats:(NSArray *)userStats;
- (void)exportToCSV:(NSString*)path;

@end
