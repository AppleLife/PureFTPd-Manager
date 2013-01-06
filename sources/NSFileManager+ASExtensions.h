//
//  NSFileManager+Extensions.h
//
//  Created by Andreas Schempp on Sat Oct 11 2003.
//  Copyright (c) 2003 Andreas Schempp. All rights reserved.
//
//  This program is free software; you can redistribute it and/or
//  modify it under the terms of the GNU General Public License
//  as published by the Free Software Foundation; either version 2
//  of the License, or (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//

#import <Foundation/Foundation.h>


@interface NSFileManager (ch_schempp_ASExtensions)

- (BOOL)createDirectoryAtPath:(NSString *)path attributes:(NSDictionary *)attributes recursive:(BOOL)recursive;

@end

@interface NSFileManager (JMSExtensions)
- (NSArray *)adjustAccessPermissionsTo:(NSString *)path forUser:(NSString *)user ofGroup:(NSString *)group modified:(BOOL *)yesNO;
- (BOOL)user:(NSString *)user ofGroup:(NSString *)group canReadDirectory:(NSString *)path;
- (BOOL)setReadPermissionAtPath:(NSString *)aPath forUser:(NSString *)user ofGroup:(NSString *)group;
- (BOOL)user:(NSString *)user ofGroup:(NSString *)group canWriteDirectory:(NSString *)path;
- (BOOL)setWritePermissionAtPath:(NSString *)aPath forUser:(NSString *)user ofGroup:(NSString *)group;
- (BOOL)user:(NSString *)user ofGroup:(NSString *)group canTraverseDirectory:(NSString *)path;
- (BOOL)setExecutePermissionAtPath:(NSString *)aPath forUser:(NSString *)user ofGroup:(NSString *)group;
- (BOOL)clearPermissionAtPath:(NSString *)aPath forUser:(NSString *)user ofGroup:(NSString *)group;
- (BOOL)checkDropBox:(NSString *)aPath;
- (NSString*)permissionsTextForFolder:(NSString *)path;
@end
