//
//  HTMLConverter.h
//  LogViewer
//
//  Created by Jean-Matthieu on 11/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "defines.h"

@interface HTMLConverter : NSObject {
    NSString *currentUser;
    NSDictionary *currentUserStats;
    NSString *currentYear;
    BOOL showMonthSummary;
    BOOL showDetails;
    BOOL fullPath;
    NSMutableDictionary *FTPStats;
    NSMutableDictionary *webpages;
    NSMutableDictionary *quicklists;
}

+ (id)getInstance;
- (id) initWithMonthSummary:(BOOL)monthSum withPath:(BOOL)path andDetails:(BOOL)details;
- (NSDictionary *)webpages;
- (void)updateFTPStats;
- (void)convertToHTML;
- (void)createUserStats:(NSDictionary *)userStats;
- (NSString *)createTableForYear:(NSString *)year withDictionary:(NSDictionary *)yearDictionary;
- (NSString *)createMonthSummary:(int)month withDictionary:(NSDictionary *)stats;
- (NSString *)createTraficForMonth:(int)month withDictionary:(NSDictionary *)stats;
- (void)addMonthToQuicklist:(NSString *)month;
- (NSString *)getHTMLQuicklists;
- (NSString *)formatSize:(NSNumber *)number;
- (NSString *) monthName:(NSString *)index;
- (void)exportToHTML:(NSString*)path;
@end
