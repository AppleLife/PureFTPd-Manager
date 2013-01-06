/*
 PureFTPd Manager
 Copyright (C) 2003-2004 Jean-Matthieu Schaffhauser <jean-matthieu@users.sourceforge.net>
 
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

#import "AKVUPaneController.h"

#import "ManagerProcessEngine.h"

@implementation AKVUPaneController

- (void)awakeFromNib
{
	SInt32 MacVersion;
	Gestalt(gestaltSystemVersion, &MacVersion);
	if (MacVersion >= 0x1040){
		[vuserUIDField setStringValue:@"1982"];
		[vuserGIDField setStringValue:@"1982"];
	}
        
}

- (BOOL) checkPaneValuesWithEngine:(id) inEngine
{
    NSMutableDictionary *myOptions = [inEngine wizardOptions];
 
    if ([vuserSkipSwitch state] == NSOnState)
    {
        [myOptions setObject:[NSNumber numberWithInt:[vuserSkipSwitch state]] 
                      forKey: VUSKIP];
		 [myOptions setObject:[NSNumber numberWithInt:[vuserUIDField intValue]]
                      forKey:VUUID];
		 [myOptions setObject:[NSNumber numberWithInt:[vuserGIDField intValue]]
                      forKey:VUGID];
		[myOptions setObject:[vuserLoginField stringValue] 
                      forKey: VULOGIN];
		 [myOptions setObject:[vuserGroupField stringValue] 
                      forKey:VUGROUP];
					  
        return YES;
    }
  else if ((![inEngine uniqUID:[vuserUIDField intValue]]) || (![inEngine uniqGID:[vuserGIDField intValue]])  ||
      (![inEngine uniqUser:[vuserLoginField stringValue]]) || (![inEngine uniqGroup:[vuserGroupField stringValue]]))
    {
      if ( ([inEngine checkUID:[vuserUIDField intValue] forUser:[vuserLoginField stringValue]]) && 
           ([inEngine checkGID:[vuserGIDField intValue] forGroup:[vuserGroupField stringValue]])  ) 
      {
          int ret = 0;
          ret = NSRunInformationalAlertPanel(NSLocalizedString(@"System accounts for virtual users match.", @"System accounts for virtual users match."), 
		  NSLocalizedString(@"The specified settings match an existing user and group on your computer (maybe they were already set up). You may safely continue or reconfigure the values, specifying different names and id numbers.", 
		  @"You may skip this step or reconfigure it, specifying new names and id numbers."), 
		  NSLocalizedString(@"Continue", @"Continue"), NSLocalizedString(@"Reconfigure", @"Reconfigure"), nil);
          
          switch (ret){
              case NSAlertDefaultReturn:
                  [vuserSkipSwitch setState:NSOnState];
                  [myOptions setObject:[NSNumber numberWithInt:[vuserSkipSwitch state]] 
                                forKey: VUSKIP];
				  [myOptions setObject:[NSNumber numberWithInt:[vuserUIDField intValue]]
                      forKey:VUUID];
					[myOptions setObject:[NSNumber numberWithInt:[vuserGIDField intValue]]
                      forKey:VUGID];
                  return YES;
                  break;
                  
              case NSAlertAlternateReturn:
                  return NO;
                  break;
          }
      }
      NSRunAlertPanel(NSLocalizedString(@"Virtual User system misconfigured.",@"Virtual User system misconfigured."),
                      NSLocalizedString(@"One or more of your settings is already defined and doesn't match your system setup. Please adjust your settings.",@"One or more of your settings is already defined and doesn't match with your system setup."),
                      NSLocalizedString(@"OK",@"OK"),
                      @"",nil);
      return NO;
    }
    else
    {
        [myOptions setObject:[NSNumber numberWithInt:[vuserSkipSwitch state]] 
                      forKey: VUSKIP];
        [myOptions setObject:[vuserLoginField stringValue] 
                      forKey: VULOGIN];
        [myOptions setObject:[NSNumber numberWithInt:[vuserUIDField intValue]]
                      forKey:VUUID];
        [myOptions setObject:[vuserGroupField stringValue] 
                      forKey:VUGROUP];
        [myOptions setObject:[NSNumber numberWithInt:[vuserGIDField intValue]]
                      forKey:VUGID];
        
        return YES;
    }
    
    
  return NO;
}

@end
