/*
    PureFTPd Manager
    Copyright (C) 2003 Jean-Matthieu Schaffhauser <jean-matthieu@users.sourceforge.net>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#import <Foundation/Foundation.h>
#import "PureController.h"

#import "defines.h"

@class PureController;

@interface VHostManager : NSObject {
    NSMutableArray *vhosts;
    NSMutableDictionary *preferences;
    BOOL modified;
    
    PureController *pureController;
}

+(id) getInstance;
-(void)addEmptyHost;
-(void)deleteHost;
-(void) updateHost;
-(NSMutableArray *)vhosts;
-(void) saveAlert;
-(void)savetoPreferences;
-(void) setupVHosts;

-(BOOL)areVhostsModified;
-(void)setModified:(BOOL)flag;

@end
