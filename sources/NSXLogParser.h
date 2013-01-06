//
//  NSXLogParser.h.h
//  PureFTP
//
//  Created by Jean-Matthieu on Thu Jan 29 2004.
//  Copyright (c) 2004 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <pcre.h>

#define OVECCOUNT 69  

@interface NSXLogParser : NSObject {
    NSMutableArray *loginfoArray;
    NSMutableArray *completeArray;
    
    int arrayCapacity;
}

/* This function sets the capacity of loginfoArray */
-(id) initWithInfoCapacity:(int) capacity;

-(NSMutableArray *) infoArray;
-(void) clearLoginfoArray;

-(void) parseLine:(NSString *)aLine withPattern:(NSString *)aPattern;



@end
