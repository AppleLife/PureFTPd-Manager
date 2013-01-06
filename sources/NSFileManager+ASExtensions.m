//
//  NSFileManager+ASExtensions.m
//
//  Created by Andreas Schempp on Mon Oct 13 2003.
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

// JMSExtensions by Jean-Matthieu Schaffhauser (01-2005)

#import "NSFileManager+ASExtensions.h"
#import <sys/stat.h>

@implementation NSFileManager (ch_schempp_ASExtensions)

- (BOOL)createDirectoryAtPath:(NSString *)path attributes:(NSDictionary *)attributes recursive:(BOOL)recursive
{
    NSFileManager *filemanager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    NSString *currentPath;
    
    if( !recursive )
        return [filemanager createDirectoryAtPath:path attributes:attributes];
    
    while( !([filemanager fileExistsAtPath:path isDirectory:&isDir] && isDir) )
    {
        currentPath = path;
        while( !([filemanager fileExistsAtPath:currentPath isDirectory:&isDir] && isDir) )
        {
            if( [filemanager fileExistsAtPath:[currentPath stringByDeletingLastPathComponent] isDirectory:&isDir] && isDir ) {
                if( ![filemanager createDirectoryAtPath: currentPath attributes: attributes] )
                    return FALSE;
            }
            else {
                currentPath = [currentPath stringByDeletingLastPathComponent];
            }
        }
    }
    
    return TRUE;
}

@end





@implementation NSFileManager (JMSExtensions)

- (NSArray *)adjustAccessPermissionsTo:(NSString *)path forUser:(NSString *)user ofGroup:(NSString *)group modified:(BOOL *)yesNO
{
    NSMutableArray *modifiedFolder = [[NSMutableArray alloc] init];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSString *currentPath;
    BOOL isDir = NO;
    BOOL isDestination = YES;
    BOOL modified = NO;
    *yesNO = NO;
    
    currentPath = path;
    //check if we're talking about a directory
    if (!([fm fileExistsAtPath:currentPath isDirectory:&isDir] && isDir))
        currentPath = [currentPath stringByDeletingLastPathComponent];
    
    while( ([fm fileExistsAtPath:currentPath isDirectory:&isDir] && isDir) && !([currentPath isEqualToString:@"/"]))
    {
        NSMutableString *infoString = [NSMutableString stringWithString:@""];
        if (isDestination){
            // the last directory should not only be executable but also readable.
            BOOL isDropBox = [self checkDropBox:currentPath];
            if (![fm user:user ofGroup:group canReadDirectory:currentPath] && !isDropBox){
                if ([fm setReadPermissionAtPath:currentPath forUser:user ofGroup:group]){
                    modified =YES;
                } else {
                    // could not set read permission to folder
                }
            }
        }
        
        if (![fm user:user ofGroup:group canTraverseDirectory:currentPath]){
            if([fm setExecutePermissionAtPath:currentPath forUser:user ofGroup:group]){
                modified = YES;
            } else {
                // could not set execute permission to folder
            }
        }
        
        if (modified)
        {
            NSString *join = NSLocalizedString(@"permissions set to", @"permissions set to");
            [infoString appendFormat:@"%@ %@ %@", currentPath, join, [fm permissionsTextForFolder:currentPath]];
            *yesNO = YES;
        }
        
        currentPath = [currentPath stringByDeletingLastPathComponent];
        isDestination = NO;
        modified=NO;
        [modifiedFolder addObject:infoString];
        
    }
    
    
    return [modifiedFolder autorelease];
}

- (BOOL)checkDropBox:(NSString *)aPath
{
    NSFileManager *fm =[NSFileManager defaultManager];
    NSDictionary *fattrs = [fm fileAttributesAtPath:aPath traverseLink:YES];
    if (!fattrs) {
        //NSLog(@"Path is incorrect!");
        return NO;
    }
    
    NSNumber *permissions = [fattrs objectForKey:NSFilePosixPermissions];
    int modeBits = [permissions intValue];
    unsigned long permBits = (modeBits & ACCESSPERMS);
    
    if ((permBits & S_IXOTH) && (permBits & S_IWOTH) && !(permBits & S_IROTH)){
        //NSLog(@"other can execute");
        return YES;
    } 
    
    return NO;
    
}

- (BOOL)user:(NSString *)user ofGroup:(NSString *)group canReadDirectory:(NSString *)path
{
    NSFileManager *fm =[NSFileManager defaultManager];
    BOOL userOwnsFile = NO;
    BOOL userGroupOwnsFile = NO;
    
    NSDictionary *fattrs = [fm fileAttributesAtPath:path traverseLink:YES];
    if (!fattrs) {
        //NSLog(@"Path is incorrect!");
        return NO;
    }
    
    if ([[fattrs objectForKey:NSFileOwnerAccountName] isEqualToString:user])
    {
        userOwnsFile = YES;
    }
    
    if ([[fattrs objectForKey:NSFileGroupOwnerAccountName] isEqualToString:group])
    {
        userGroupOwnsFile = YES;
    }
    
    NSNumber *permissions = [fattrs objectForKey:NSFilePosixPermissions];
    int modeBits = [permissions intValue];
    unsigned long permBits = (modeBits & ACCESSPERMS);
    //NSLog(@"%@", [perms description]);
    
    if (userOwnsFile && ((permBits & S_IRUSR)) )
    {
        //NSLog(@"user can read");
        return YES;
    } else if (userGroupOwnsFile && ((permBits & S_IRGRP)) ){
        //NSLog(@"user group can read");
        return YES;
    }  else if (!userOwnsFile && !userGroupOwnsFile && (permBits & S_IROTH)){
        //NSLog(@"other can read");
        return YES;
    } 
    
    return NO;
}

- (BOOL)setReadPermissionAtPath:(NSString *)aPath forUser:(NSString *)user ofGroup:(NSString *)group
{
    NSFileManager *fm =[NSFileManager defaultManager];
    BOOL userOwnsFile = NO;
    BOOL userGroupOwnsFile = NO;
    
    NSMutableDictionary *fattrs = [NSMutableDictionary dictionaryWithDictionary:[fm fileAttributesAtPath:aPath traverseLink:YES]];
    NSNumber *permissions = [fattrs objectForKey:NSFilePosixPermissions];
    int modeBits = [permissions intValue];
    unsigned long permBits = (modeBits & ACCESSPERMS);
    
    if ([[fattrs objectForKey:NSFileOwnerAccountName] isEqualToString:user])
    {
        userOwnsFile = YES;
    }
    
    if ([[fattrs objectForKey:NSFileGroupOwnerAccountName] isEqualToString:group])
    {
        userGroupOwnsFile = YES;
    }
    
    if (userOwnsFile)
    {
        permBits|=S_IRUSR;
        [fattrs setObject:[NSNumber numberWithInt:permBits] forKey:NSFilePosixPermissions];
    } else if (userGroupOwnsFile){
        permBits|=S_IRGRP;
        [fattrs setObject:[NSNumber numberWithInt:permBits] forKey:NSFilePosixPermissions];
    } else{
        permBits|=S_IROTH;
        [fattrs setObject:[NSNumber numberWithInt:permBits] forKey:NSFilePosixPermissions];
    } 
    
    
    return [fm changeFileAttributes:fattrs atPath:aPath];
}

- (BOOL)user:(NSString *)user ofGroup:(NSString *)group canWriteDirectory:(NSString *)path
{
    NSFileManager *fm =[NSFileManager defaultManager];
    BOOL userOwnsFile = NO;
    BOOL userGroupOwnsFile = NO;
    
    NSDictionary *fattrs = [fm fileAttributesAtPath:path traverseLink:YES];
    if (!fattrs) {
        NSLog(@"Path is incorrect!");
        return NO;
    }
    
    if ([[fattrs objectForKey:NSFileOwnerAccountName] isEqualToString:user])
    {
        userOwnsFile = YES;
    }
    
    if ([[fattrs objectForKey:NSFileGroupOwnerAccountName] isEqualToString:group])
    {
        userGroupOwnsFile = YES;
    }
    
    NSNumber *permissions = [fattrs objectForKey:NSFilePosixPermissions];
    int modeBits = [permissions intValue];
    unsigned long permBits = (modeBits & ACCESSPERMS);
    //NSLog(@"%@", [perms description]);
    
    if (userOwnsFile && ((permBits & S_IWUSR)) )
    {
        //NSLog(@"user can write");
        return YES;
    } else if (userGroupOwnsFile && ((permBits & S_IWGRP)) ){
        //NSLog(@"user group can write");
        return YES;
    }else if (!userOwnsFile && !userGroupOwnsFile && (permBits & S_IWOTH)){
        //NSLog(@"other can write");
        return YES;
    } 
    
    return NO;
    
}

- (BOOL)setWritePermissionAtPath:(NSString *)aPath forUser:(NSString *)user ofGroup:(NSString *)group
{
    NSFileManager *fm =[NSFileManager defaultManager];
    BOOL userOwnsFile = NO;
    BOOL userGroupOwnsFile = NO;
    
    NSMutableDictionary *fattrs = [NSMutableDictionary dictionaryWithDictionary:[fm fileAttributesAtPath:aPath traverseLink:YES]];
    NSNumber *permissions = [fattrs objectForKey:NSFilePosixPermissions];
    int modeBits = [permissions intValue];
    unsigned long permBits = (modeBits & ACCESSPERMS);
    
    if ([[fattrs objectForKey:NSFileOwnerAccountName] isEqualToString:user])
    {
        userOwnsFile = YES;
    }
    
    if ([[fattrs objectForKey:NSFileGroupOwnerAccountName] isEqualToString:group])
    {
        userGroupOwnsFile = YES;
    }
    
    if (userOwnsFile)
    {
        permBits|=S_IWUSR;
        [fattrs setObject:[NSNumber numberWithInt:permBits] forKey:NSFilePosixPermissions];
    } else if (userGroupOwnsFile){
        permBits|=S_IWGRP;
        [fattrs setObject:[NSNumber numberWithInt:permBits] forKey:NSFilePosixPermissions];
    } else{
        permBits|=S_IWOTH;
        [fattrs setObject:[NSNumber numberWithInt:permBits] forKey:NSFilePosixPermissions];
    } 
    
    
    return [fm changeFileAttributes:fattrs atPath:aPath];
}

- (BOOL)user:(NSString *)user ofGroup:(NSString *)group canTraverseDirectory:(NSString *)path
{
    NSFileManager *fm =[NSFileManager defaultManager];
    BOOL userOwnsFile = NO;
    BOOL userGroupOwnsFile = NO;
    
    NSDictionary *fattrs = [fm fileAttributesAtPath:path traverseLink:YES];
    if (!fattrs) {
        //NSLog(@"Path is incorrect!");
        return NO;
    }
    
    if ([[fattrs objectForKey:NSFileOwnerAccountName] isEqualToString:user])
    {
        userOwnsFile = YES;
    }
    
    if ([[fattrs objectForKey:NSFileGroupOwnerAccountName] isEqualToString:group])
    {
        userGroupOwnsFile = YES;
    }
    
    NSNumber *permissions = [fattrs objectForKey:NSFilePosixPermissions];
    int modeBits = [permissions intValue];
    unsigned long permBits = (modeBits & ACCESSPERMS);
    //NSLog(@"%@", [perms description]);
    
    if (userOwnsFile && ((permBits & S_IXUSR)) )
    {
        //NSLog(@"user can execute");
        return YES;
    } else if (userGroupOwnsFile && ((permBits & S_IXGRP)) ){
        //NSLog(@"user group can execute");
        return YES;
    } else if (!userOwnsFile && !userGroupOwnsFile && (permBits & S_IXOTH)){
        //NSLog(@"other can execute");
        return YES;
    } 
    
    return NO;
    
}



- (BOOL)setExecutePermissionAtPath:(NSString *)aPath forUser:(NSString *)user ofGroup:(NSString *)group
{
    NSFileManager *fm =[NSFileManager defaultManager];
    BOOL userOwnsFile = NO;
    BOOL userGroupOwnsFile = NO;
    
    NSMutableDictionary *fattrs = [NSMutableDictionary dictionaryWithDictionary:[fm fileAttributesAtPath:aPath traverseLink:YES]];
    NSNumber *permissions = [fattrs objectForKey:NSFilePosixPermissions];
    int modeBits = [permissions intValue];
    unsigned long permBits = (modeBits & ACCESSPERMS);
    
    if ([[fattrs objectForKey:NSFileOwnerAccountName] isEqualToString:user])
    {
        userOwnsFile = YES;
    }
    
    if ([[fattrs objectForKey:NSFileGroupOwnerAccountName] isEqualToString:group])
    {
        userGroupOwnsFile = YES;
    }
    
    if (userOwnsFile)
    {
        permBits|=S_IXUSR;
        [fattrs setObject:[NSNumber numberWithInt:permBits] forKey:NSFilePosixPermissions];
    } else if (userGroupOwnsFile){
        permBits|=S_IXGRP;
        [fattrs setObject:[NSNumber numberWithInt:permBits] forKey:NSFilePosixPermissions];
    } else{
        permBits|=S_IXOTH;
        [fattrs setObject:[NSNumber numberWithInt:permBits] forKey:NSFilePosixPermissions];
    } 
   
    
    return [fm changeFileAttributes:fattrs atPath:aPath];
}


- (BOOL)clearPermissionAtPath:(NSString *)aPath forUser:(NSString *)user ofGroup:(NSString *)group
{
    NSFileManager *fm =[NSFileManager defaultManager];
    BOOL userOwnsFile = NO;
    BOOL userGroupOwnsFile = NO;
    
    NSMutableDictionary *fattrs = [NSMutableDictionary dictionaryWithDictionary:[fm fileAttributesAtPath:aPath traverseLink:YES]];
    NSNumber *permissions = [fattrs objectForKey:NSFilePosixPermissions];
    int modeBits = [permissions intValue];
    unsigned long permBits = (modeBits & ACCESSPERMS);
    unsigned long newPerms = 0;
    if ([[fattrs objectForKey:NSFileOwnerAccountName] isEqualToString:user])
    {
        userOwnsFile = YES;
    }
    
    if ([[fattrs objectForKey:NSFileGroupOwnerAccountName] isEqualToString:group])
    {
        userGroupOwnsFile = YES;
    }
    
    if (userOwnsFile)
    {
        if (permBits & S_IRGRP)
            newPerms |= S_IRGRP;
        
        if (permBits & S_IWGRP)
            newPerms |= S_IWGRP;
        
        if (permBits & S_IXGRP)
            newPerms |= S_IXGRP;
        
        if (permBits & S_IROTH)
            newPerms |= S_IROTH;
        
        if (permBits & S_IROTH)
            newPerms |= S_IWOTH;
        
        if (permBits & S_IXOTH)
            newPerms |= S_IXOTH;
      
        //[fattrs setObject:[NSNumber numberWithInt:permBits] forKey:NSFilePosixPermissions];
    } else if (userGroupOwnsFile){
        if (permBits & S_IRUSR)
            newPerms |= S_IRUSR;
        
        if (permBits & S_IRUSR)
            newPerms |= S_IWUSR;
        
        if (permBits & S_IXUSR)
            newPerms |= S_IXUSR;
        
        
        if (permBits & S_IROTH)
            newPerms |= S_IROTH;
        
        if (permBits & S_IROTH)
            newPerms |= S_IWOTH;
        
        if (permBits & S_IXOTH)
            newPerms |= S_IXOTH;
        
       // permBits&=S_IRGRP;
        //permBits&=S_IWGRP;
        //permBits&=S_IXGRP;
        //[fattrs setObject:[NSNumber numberWithInt:permBits] forKey:NSFilePosixPermissions];
    } else{
        if (permBits & S_IRUSR)
            newPerms |= S_IRUSR;
        
        if (permBits & S_IRUSR)
            newPerms |= S_IWUSR;
        
        if (permBits & S_IXUSR)
            newPerms |= S_IXUSR;
        
        if (permBits & S_IRGRP)
            newPerms |= S_IRGRP;
        
        if (permBits & S_IWGRP)
            newPerms |= S_IWGRP;
        
        if (permBits & S_IXGRP)
            newPerms |= S_IXGRP;
        
       // permBits=S_IROTH;
        //permBits=S_IWOTH;
        //permBits=S_IXOTH;
        //[fattrs setObject:[NSNumber numberWithInt:permBits] forKey:NSFilePosixPermissions];
    } 
    
    [fattrs setObject:[NSNumber numberWithInt:newPerms] forKey:NSFilePosixPermissions];
    return [fm changeFileAttributes:fattrs atPath:aPath];
}

// adapted from CocoaTechFoundation
- (NSString*)permissionsTextForFolder:(NSString *)path
{   
    NSFileManager *fm =[NSFileManager defaultManager];
    
    NSMutableDictionary *fattrs = [NSMutableDictionary dictionaryWithDictionary:[fm fileAttributesAtPath:path traverseLink:YES]];
    NSNumber *permissions = [fattrs objectForKey:NSFilePosixPermissions];
    int modeBits = [permissions intValue];
    
    NSString* perm = @"";
    int chmodNum;
    unsigned long permBits = (modeBits & ACCESSPERMS);
    
    if (S_ISDIR(modeBits))
        perm = [perm stringByAppendingString:@"d"];
    else if (S_ISCHR(modeBits))
        perm = [perm stringByAppendingString:@"c"];
    else if (S_ISBLK(modeBits))
        perm = [perm stringByAppendingString:@"b"];
    else if (S_ISLNK(modeBits))
        perm = [perm stringByAppendingString:@"l"];
    else if (S_ISSOCK(modeBits))
        perm = [perm stringByAppendingString:@"s"];
    else if (S_ISWHT(modeBits))
        perm = [perm stringByAppendingString:@"w"];
    else if (S_ISREG(modeBits))
        perm = [perm stringByAppendingString:@"-"];
    else
        perm = [perm stringByAppendingString:@" "];  // what is it?
    
    // Owner
    perm = [perm stringByAppendingString:(permBits & S_IRUSR) ? @"r" : @"-"];
    perm = [perm stringByAppendingString:(permBits & S_IWUSR) ? @"w" : @"-"];
    
    if (permBits & S_IXUSR)
    {
        if ((S_ISUID & modeBits) || (S_ISGID & modeBits))
            perm = [perm stringByAppendingString:@"s"];
        else
            perm = [perm stringByAppendingString:@"x"];
    }
    else
    {
        if ((S_ISUID & modeBits) || (S_ISGID & modeBits))
            perm = [perm stringByAppendingString:@"S"];
        else
            perm = [perm stringByAppendingString:@"-"];
    }
    
    // Group
    perm = [perm stringByAppendingString:(permBits & S_IRGRP) ? @"r" : @"-"];
    perm = [perm stringByAppendingString:(permBits & S_IWGRP) ? @"w" : @"-"];
    
    if (permBits & S_IXGRP)
    {
        if ((S_ISUID & modeBits) || (S_ISGID & modeBits))
            perm = [perm stringByAppendingString:@"s"];
        else
            perm = [perm stringByAppendingString:@"x"];
    }
    else
    {
        if ((S_ISUID & modeBits) || (S_ISGID & modeBits))
            perm = [perm stringByAppendingString:@"S"];
        else
            perm = [perm stringByAppendingString:@"-"];
    }
    
    // Others
    perm = [perm stringByAppendingString:(permBits & S_IROTH) ? @"r" : @"-"];
    perm = [perm stringByAppendingString:(permBits & S_IWOTH) ? @"w" : @"-"];
    
    if (permBits & S_IXOTH)
    {
        if ((S_ISUID & modeBits) || (S_ISGID & modeBits))
            perm = [perm stringByAppendingString:@"s"];
        else
        {
            // check sticky bit
            if (S_ISVTX & modeBits)
                perm = [perm stringByAppendingString:@"t"];
            else
                perm = [perm stringByAppendingString:@"x"];
        }
    }
    else
    {
        if ((S_ISUID & modeBits) || (S_ISGID & modeBits))
            perm = [perm stringByAppendingString:@"S"];
        else
        {
            // check sticky bit
            if (S_ISVTX & modeBits)
                perm = [perm stringByAppendingString:@"T"];
            else
                perm = [perm stringByAppendingString:@"-"];
        }
    }
    
    // add - chmod 755
    chmodNum = 100 * ((permBits & S_IRWXU) >> 6);  // octets
    chmodNum += 10 * ((permBits & S_IRWXG) >> 3);
    chmodNum += 1 * (permBits & S_IRWXO);
    
    char buff[20];
    snprintf(buff, 20, "%03d", chmodNum);
    
    perm = [perm stringByAppendingString:@" ("];
    perm = [perm stringByAppendingString:[NSString stringWithUTF8String:buff]];
    perm = [perm stringByAppendingString:@")"];
    
    return perm;
}


@end
