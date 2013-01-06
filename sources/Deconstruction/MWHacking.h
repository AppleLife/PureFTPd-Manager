//
//  MWHacking.h
//  gDisk
//
//  Created by Wagner Marie on 03/02/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MWHacking : NSObject {
}

+ (NSArray *)methodsOfObject:(id)anObject classObject:(BOOL)flag;
+ (NSArray *)ivarsOfObject:(id)anObject classObject:(BOOL)flag;
+ (NSString *)describeObject:(id)anObject classObject:(BOOL)flag;
@end

