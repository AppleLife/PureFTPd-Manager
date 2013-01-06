//
//  NSXTableMenu.h
//
//  Tab Size: 3
// -----------------------------------------------------------------
//  Copyright (c) 2003 Aaron Sittig. All rights reserved.
//
//  Redistribution and use in source and binary forms, with or
//  without modification, are permitted provided that the
//  following conditions are met:
//
//  1 Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//  2 Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in the
//    documentation and/or other materials provided with distribution.
//  3 Neither the name of Aaron Sittig nor the names of contributors
//    may be used to endorse or promote products derived from this
//    software without specific prior written permission.
//  -----------------------------------------------------------------

//  NSXTableMenu is an NSTableView Category to facilitate attaching a
//  popup menu to the upper right hand corner.

@interface NSTableView (NSXTableMenu)

- (NSMenu*)tableMenu;
- (void)setTableMenu:(NSMenu*)menu;

@end

