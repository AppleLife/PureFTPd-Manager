//
//  HTMLConverter.m
//  LogViewer
//
//  Created by Jean-Matthieu on 11/10/2004.
//  Copyright 2004 __MyCompanyName__. All rights reserved.
//

#import "HTMLConverter.h"
#import "UserStatsController.h"
#import <unistd.h>

static HTMLConverter *converter = nil;

@implementation HTMLConverter
+ (id)getInstance
{
    if (converter == nil){
        [self init];
    }
    return converter;
}

- (id)init
{
    self = [super init];
    if(self)
    {
        converter = self;
        currentUser = nil;
        currentUserStats = nil;
        currentYear = nil;
        showMonthSummary = NO;
        showDetails =NO;
        fullPath = NO;
        if (geteuid()==0)
            [self updateFTPStats];
        FTPStats = [[NSMutableDictionary alloc] initWithContentsOfFile:@"/var/log/FTPStats.plist"];
        webpages = [[NSMutableDictionary alloc] init];
        quicklists = [[NSMutableDictionary alloc] init];
        return self;
    }
    
    return nil;
}

- (id) initWithMonthSummary:(BOOL)monthSum withPath:(BOOL)path andDetails:(BOOL)details
{
    id me = [self init];
    showMonthSummary = monthSum;
    showDetails = details;
    fullPath = path;
    return me;
}

- (void) dealloc
{
    [FTPStats release];
    [webpages release];
    [quicklists release];
    [super dealloc];
}

- (NSDictionary *)webpages
{
    return webpages;
}

- (void)updateFTPStats
{
    
    NSDictionary *preferences = nil;
    if (nil != (preferences = [NSDictionary dictionaryWithContentsOfFile:PureFTPPreferenceFile]))
    {
            
        NSString *logPath = [preferences objectForKey:PureFTPLogLocation];
        NSString *logFormat = [preferences objectForKey:PureFTPLogFormat];
        NSString *pattern = nil;
        if ([logFormat isEqualToString:@"CLF"])
            pattern = [NSString stringWithString:CLF_PATTERN];
        else if ([logFormat isEqualToString:@"W3C"])
            pattern = [NSString stringWithString:W3C_PATTERN];
        
        UserStatsController *myUserStats = [[UserStatsController alloc] init];
        [myUserStats parseFile:logPath withPattern: pattern];
      
        [myUserStats release];
    }    
    
   
}

- (void) convertToHTML
{
    NSArray *users = [FTPStats allKeys];
    NSEnumerator *userEnum = [users objectEnumerator];
    NSString *aUser = nil;
    while ((aUser = [userEnum nextObject])!= nil)
    {
        id userDict = [FTPStats objectForKey:aUser];
        if ([userDict isKindOfClass:[NSArray class]]){
            currentUser = aUser;
            currentUserStats = userDict;
            [self createUserStats:[userDict objectAtIndex:0]];
        }
    }
}

- (void)createUserStats:(NSDictionary *)userStats
{
    NSString *HTMLHeader = [NSString stringWithFormat:@"<HTML><BODY BGCOLOR=#FFFFFF><H2>FTP Statistics for %@</H2>", currentUser];
    NSString *HTMLFooter = @"</TD></TR></TABLE></DIV></BODY></HTML>";
    NSMutableString *HTMLContent = [[NSMutableString alloc] init];
    
    NSArray *years = [userStats allKeys];
    NSEnumerator *yearEnum = [years objectEnumerator];
    NSString *aYear = nil;
    while ((aYear = [yearEnum nextObject]) != nil)
    {
        NSString *tableForYear = [self createTableForYear:aYear withDictionary:[userStats objectForKey:aYear]];
        [HTMLContent appendFormat:@"\n%@", tableForYear];
    }
    NSString *HTMLPage = nil;
    
    if (showDetails)
    {
        NSString *HTMLquicklists = [self getHTMLQuicklists];
        HTMLPage = [NSString stringWithFormat:@"%@\n<DIV ALIGN=RIGHT>%@</DIV><BR>\n%@\n%@", HTMLHeader, HTMLquicklists, HTMLContent, HTMLFooter];
        
    } else 
    {
        HTMLPage = [NSString stringWithFormat:@"%@\n%@\n%@", HTMLHeader, HTMLContent, HTMLFooter];
    }
    
    
    [webpages setObject:HTMLPage forKey:currentUser];
    [HTMLContent release];

}

- (NSString *)createTableForYear:(NSString *)year withDictionary:(NSDictionary *)yearDictionary
{
    int i = 1;
    
	// put & get
	NSString *up = [[yearDictionary objectForKey:@"yearTotal"] objectForKey:@"PUT"];
	NSNumber *upload=nil;
	
	if (up == nil)
		upload = [NSNumber numberWithInt:0];
	else 
		upload = [NSNumber numberWithInt:[up intValue]];
		
	NSString *down = [[yearDictionary objectForKey:@"yearTotal"] objectForKey:@"GET"];
	NSNumber *download=nil;
	
	if (down == nil)
		download = [NSNumber numberWithInt:0];
	else 
		download = [NSNumber numberWithInt:[down intValue]];
	
    NSString *tableHeader = @"<DIV ALIGN=CENTER><TABLE BODER=0 CELLSPACING=1 CELLPADDING=1 WIDTH=90%%  BGCOLOR=#000000><TR><TD><TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0 WIDTH=100%%  ALIGN=CENTER BGCOLOR=#FFFFFF>";
    NSString *tableFooter = @"</TABLE>\n";
    NSString *yearTotalRow = [NSString stringWithFormat:@"<TR>\n\
    <TD ALIGN=LEFT><B>&nbsp;%@</B></TD>\n\
    <TD ALIGN=RIGHT>Year Total (Upload / Download): <B>%@ / %@</B>&nbsp;</TD>\n\
    </TR>", year, [[self formatSize:upload] description], [[self formatSize:download] description] ];
    
    NSMutableString *tableContent = [[NSMutableString alloc] init];
    
    NSArray *monthKeys = [yearDictionary allKeys];
    NSEnumerator *monthEnum = [monthKeys objectEnumerator];
    NSString *mKey = nil;
    while((mKey = [monthEnum nextObject]) != nil)
    {
        NSString *bgcolor = @"#2F3540";
        if (![mKey isEqualToString:@"yearTotal"])
        {
            /*if (i%2 == 0)
            {
                bgcolor=@"#2F3540";
            }*/
			
			NSString *m_up = [[[yearDictionary objectForKey:mKey]  objectForKey:@"monthTotal"] objectForKey:@"PUT"];
			NSNumber *m_upload=nil;
	
			if (m_up == nil)
				m_upload = [NSNumber numberWithInt:0];
			else 
				m_upload = [NSNumber numberWithInt:[m_up intValue]];
		
			NSString *m_down = [[[yearDictionary objectForKey:mKey]  objectForKey:@"monthTotal"] objectForKey:@"GET"];
			NSNumber *m_download=nil;
	
			if (m_down == nil)
				m_download = [NSNumber numberWithInt:0];
			else 
				m_download = [NSNumber numberWithInt:[m_down intValue]];

			
            [tableContent appendFormat:@"<TR BGCOLOR=%@>\n\
            <TD ALIGN=LEFT><FONT COLOR=#FFFFFF><A NAME=%@><B>&nbsp;&nbsp;%@</B></A></FONT></TD>\n\
            <TD ALIGN=RIGHT><FONT COLOR=#FFFFFF>Upload / Download:&nbsp; <B>%@&nbsp;/&nbsp;%@</B></FONT></TD>\n\
            </TR>\n", bgcolor, [self monthName:mKey],[self monthName:mKey], 
			[[self formatSize:m_upload] description], [[self formatSize:m_download] description]];
            if (showMonthSummary)
            {
                 [tableContent appendFormat:@"<TR><TD COLSPAN=2>%@</TD></TR>",[self createMonthSummary:[mKey intValue] withDictionary:currentUserStats]];
            }
            
            if (showDetails)
            {
                NSArray *anArray = [quicklists objectForKey:year];
                if (anArray == nil)
                {
                    [quicklists setObject:[NSMutableArray array] forKey:year];
                }
                
                currentYear = year;
                [tableContent appendFormat:@"<TR><TD COLSPAN=2>%@</TD></TR>",[self createTraficForMonth:[mKey intValue] withDictionary:currentUserStats]];
            }
            i++;
        }
        
    }
    
    NSString *returnedString = [NSString stringWithFormat:@"%@%@%@%@", tableHeader, yearTotalRow, tableContent, tableFooter];
    [tableContent release];
    
    return returnedString;
    
}

- (NSString *)createMonthSummary:(int)month withDictionary:(NSDictionary *)stats
{
    NSString *tableHeader = @"<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0 WIDTH=100%%  ALIGN=CENTER BGCOLOR=#A5AAB6>";
    NSString *tableFooter = @"</TABLE>\n";
    NSMutableString *tableContent = [[NSMutableString alloc] init];
    NSMutableDictionary *monthSummary = [[NSMutableDictionary alloc] init];
    
    NSEnumerator *statsEnum = [stats objectEnumerator];
    NSDictionary *entry = [statsEnum nextObject];
    
    while ((entry = [statsEnum nextObject]) !=nil)
    {
        NSCalendarDate *date = [NSCalendarDate dateWithString:[[entry objectForKey:@"tc_date"]description] calendarFormat:@"%Y-%m-%d %H:%M:%S %z"];
       
        if (month == [date monthOfYear])
        {  
            NSString *day = [NSString stringWithFormat:@"%d",[date dayOfMonth]];
            NSNumber *totalPUTForDay = nil;
            NSNumber *totalGETForDay = nil;
            
            NSArray *dayTransfer = [monthSummary objectForKey:day];
            if (dayTransfer != nil)
            {
                totalPUTForDay = [NSNumber numberWithDouble:[[dayTransfer objectAtIndex:0] doubleValue]];
                totalGETForDay = [NSNumber numberWithDouble:[[dayTransfer objectAtIndex:1] doubleValue]];
            } else {
                totalPUTForDay = [NSNumber numberWithDouble:0.0];
                totalGETForDay = [NSNumber numberWithDouble:0.0];
               
            }
            
            NSString *entryType = [entry objectForKey:@"tc_type"];
            NSNumber *newPUTTotal=nil;
            NSNumber *newGETTotal=nil;
            if ([entryType isEqualToString:@"PUT"])
            {
                newPUTTotal = [NSNumber numberWithDouble:[totalPUTForDay doubleValue]+[[entry objectForKey:@"tc_size"] doubleValue]];
                newGETTotal = [NSNumber numberWithDouble:[totalGETForDay doubleValue]];
            } else {
                newGETTotal = [NSNumber numberWithDouble:[totalGETForDay doubleValue]+[[entry objectForKey:@"tc_size"] doubleValue]];
                newPUTTotal = [NSNumber numberWithDouble:[totalPUTForDay doubleValue]];
            }
            
            NSMutableArray *thisDay = [NSMutableArray array];
            [thisDay addObject:newPUTTotal];
            [thisDay addObject:newGETTotal];
            [monthSummary setObject:thisDay forKey:day];
        }
    }
    
    
    NSArray *m_monthDays = [monthSummary allKeys];
    NSArray *monthDays =nil;
    
    NSMutableArray *daysArray = [[NSMutableArray alloc] init];
    NSEnumerator *keyEnum = [m_monthDays objectEnumerator];
    NSString *key = nil;
    
    while(key = [keyEnum nextObject]){
        NSDictionary *aDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:[key intValue]] forKey:@"days"];
        [daysArray addObject:aDict];
    }
    
    UInt32          response;

    OSStatus err = Gestalt(gestaltSystemVersion, (SInt32 *) &response);
    
    if ( (err == noErr) && (response >= 0x01030) ) {        
        NSSortDescriptor *lastNameDescriptor=[[[NSSortDescriptor alloc] initWithKey:@"days" 
                                                                          ascending:YES
                                                                           selector:@selector(compare:)] autorelease];
        NSArray *sortDescriptors=[NSArray arrayWithObject:lastNameDescriptor];
        
        if (monthDays)
            [monthDays release];
        monthDays=[[NSArray alloc] initWithArray:[daysArray sortedArrayUsingDescriptors:sortDescriptors]];
    } else {
        if (monthDays)
            [monthDays release];
        monthDays = [[NSArray alloc] initWithArray:daysArray];
    }
    
    [daysArray release];
    
    
    NSEnumerator *daysEnum = [monthDays objectEnumerator];
    
    NSDictionary *aDay = nil;
    [tableContent appendString:@"<TR><TD ALIGN=LEFT><FONT COLOR=#FFFFFF><B>Month Summary:</B></FONT>"];
    while ((aDay = [daysEnum nextObject]) != nil )
    {
        NSArray *totalForDay = [monthSummary objectForKey:[[aDay objectForKey:@"days"] stringValue]];
        NSString *put = [[self formatSize:[totalForDay objectAtIndex:0]] description];
        NSString *get = [[self formatSize:[totalForDay objectAtIndex:1]] description];
        [tableContent appendFormat:@"</TD></TR><TR><TD ALIGN=LEFT><FONT COLOR=#FFFFFF><B>&nbsp;&nbsp;%@</B> - Download: %@ - Upload: %@</FONT>", [aDay objectForKey:@"days"], get, put];
    }
    [tableContent appendString:@"</TD></TR>"];
    
    NSString *returnedString = [NSString stringWithFormat:@"%@%@%@", tableHeader, tableContent, tableFooter];
    [tableContent release];
    [monthSummary release];
    
    return returnedString;
    
}

- (NSString *)createTraficForMonth:(int)month withDictionary:(NSDictionary *)stats
{
    int i = 2;
    NSString *tableHeader = @"<TABLE BORDER=0 CELLSPACING=0 CELLPADDING=0 WIDTH=100%%  ALIGN=CENTER BGCOLOR=#7691BA>";
    NSString *tableFooter = @"</TABLE>\n";
    NSMutableString *tableContent = [[NSMutableString alloc] init];
    
    NSEnumerator *statsEnum = [stats objectEnumerator];
    NSDictionary *entry = [statsEnum nextObject];
    
    while ((entry = [statsEnum nextObject]) !=nil)
    {
        NSCalendarDate *date = [NSCalendarDate dateWithString:[[entry objectForKey:@"tc_date"]description] calendarFormat:@"%Y-%m-%d %H:%M:%S %z"];
        NSString *bgcolor = @"#7691BA";
        NSString *theMonth = [self monthName:[NSString stringWithFormat:@"%d", month]];
        NSString *path = nil;
        if (month == [date monthOfYear])
        {   
            [self addMonthToQuicklist:theMonth];
            
            
            if (i%2 == 0)
            {
                bgcolor=@"#6692D2";
            }
            if (fullPath)
            {
                path = [entry objectForKey:@"tc_filename"];
            } else {
                path = [[entry objectForKey:@"tc_filename"] lastPathComponent];
            }
            
            [tableContent appendFormat:@"<TR  BGCOLOR=%@>\n\
    <TD ALIGN=LEFT><FONT SIZE=1>&nbsp;&nbsp;%d</FONT></TD>\n\
    <TD ALIGN=RIGHT><FONT SIZE=1><B>%@&nbsp;&nbsp;%@&nbsp;&nbsp;</B></FONT></TD>\n\
    </TR>\n\
    <TR  BGCOLOR=%@>\n\
    <TD ALIGN=LEFT><FONT SIZE=1>&nbsp;&nbsp;%@</FONT></TD>\n\
    <TD ALIGN=RIGHT><FONT SIZE=1>%@&nbsp;&nbsp;</FONT></TD>\n\
    </TR>\n", bgcolor, [date dayOfMonth], [entry objectForKey:@"UserIP"], 
                [[self formatSize: [NSNumber numberWithDouble:[[entry objectForKey:@"tc_size"] doubleValue]]] description], 
                bgcolor,
                [entry objectForKey:@"tc_type"], path];
            i++;
        }
    }
    
    NSString *returnedString = [NSString stringWithFormat:@"%@%@%@", tableHeader, tableContent, tableFooter];
    [tableContent release];
    
    return returnedString;
}

- (void)addMonthToQuicklist:(NSString *)month
{
    NSArray *monthArray = [quicklists objectForKey:currentYear];
    NSEnumerator *anEnum = [monthArray objectEnumerator];
    NSString *aMonth = nil;
    BOOL shouldAddMonth = YES;
    
    while ((aMonth = [anEnum nextObject]) != nil)
    {
        if ([aMonth isEqualToString:month])
            shouldAddMonth = NO;
    }
    if (shouldAddMonth)
        [[quicklists objectForKey:currentYear] addObject:month];
    
}

- (NSString *)getHTMLQuicklists
{
    NSMutableString *linksContent = [[NSMutableString alloc] init];
    NSArray *years = [quicklists allKeys];
    NSEnumerator *myEnum = [years objectEnumerator];
    NSString *key = nil;
    
    while ((key = [myEnum nextObject]) != nil)
    {
        [linksContent appendFormat:@"%@ - Quickjump to : <select name=\"menu\" size=1 onchange=\"location.href=this.value\">\n\
    <option selected value=\"\">Choose...</option>\n", key];
        NSArray *links = [quicklists objectForKey:key];
        NSEnumerator *linkEnum = [links objectEnumerator];
        NSString *aLink = nil;
        while ((aLink = [linkEnum nextObject]) != nil)
        {
            [linksContent appendFormat:@"<option value=\"#%@\">%@</option>\n", aLink, aLink];
        }
        [linksContent appendString:@"</select><BR>"];
    }
    
    NSString *returnString = [NSString stringWithFormat:@"%@", linksContent];
    [linksContent release];
    [quicklists removeAllObjects];
    return returnString;
}

- (void)exportToHTML:(NSString*)path
{
    NSString *baseDir = path;
    NSArray *pages = [webpages allKeys];
    NSEnumerator *pagesEnum = [pages objectEnumerator];
    NSString *filename = nil;
    
    while ((filename = [pagesEnum nextObject]) != nil)
    {
        NSString *thePage = [webpages objectForKey:filename];
        [thePage writeToFile:[NSString stringWithFormat:@"%@/%@.html", baseDir, filename] atomically:YES];
    }
    
    NSMutableString  *topFrame = [[NSMutableString alloc] init];
    [topFrame appendString:@"<HTML><BODY BGCOLOR=#FFFFFF><H2>PureFTPd Usage</H2><DIV ALIGN=RIGHT><form action="">Show user: <select name=\"menu\" size=1 onchange=\"parent.frames[1].location.href =this.form.menu.options[this.form.menu.options.selectedIndex].value\">\n\
    <option selected value=\"\">Choose...</option>\n"];
    
    NSArray *sortedArray = nil;
    //NSArray *users = [webpages allKeys];
   // NSEnumerator *usersEnum = [users objectEnumerator];
    
    NSArray *keyArray = [NSArray arrayWithArray:[webpages allKeys]];
    
    NSMutableArray *usersArray = [[NSMutableArray alloc] init];
    NSEnumerator *keyEnum = [keyArray objectEnumerator];
    NSString *key = nil;
    while(key = [keyEnum nextObject]){
        NSDictionary *aDict = [NSDictionary dictionaryWithObject:key forKey:@"account"];
        [usersArray addObject:aDict];
    }
    
    
    UInt32          response;
    
    OSStatus err = Gestalt(gestaltSystemVersion, (SInt32 *) &response);
    
    if ( (err == noErr) && (response >= 0x01030) ) {            
        NSSortDescriptor *lastNameDescriptor=[[[NSSortDescriptor alloc] initWithKey:@"account" 
                                                                          ascending:YES
                                                                           selector:@selector(caseInsensitiveCompare:)] autorelease];
        NSArray *sortDescriptors=[NSArray arrayWithObject:lastNameDescriptor];
        
        if (sortedArray)
            [sortedArray release];
        sortedArray=[[NSArray alloc] initWithArray:[usersArray sortedArrayUsingDescriptors:sortDescriptors]];
    } else {
        if (sortedArray)
            [sortedArray release];
        sortedArray = [[NSArray alloc] initWithArray:usersArray];
    }
    
    [usersArray release];
    
    
    
    id aUser = nil;
    NSEnumerator *sortEnum = [sortedArray objectEnumerator];
    while ((aUser = [sortEnum nextObject]) != nil)
    {   
        NSString *username = [aUser objectForKey:@"account"];
        [topFrame appendFormat:@"<option value=\"%@.html\">%@</option>\n", username, username];
    }
    
    [topFrame appendString:@"</form></DIV></BODY></HTML>"];
    [topFrame writeToFile:[NSString stringWithFormat:@"%@/topframe.html", baseDir] atomically:YES];
    
    NSString *blank = @"<HTML><BODY BGCOLOR=#FFFFFF></BODY></HTML>";
    [blank writeToFile:[NSString stringWithFormat:@"%@/blank.html", baseDir] atomically:YES];
    
    NSString *index = @"<HTML><FRAMESET rows=\"85, *\" BORDER=NO><FRAME scrolling=\"NO\" src=\"topframe.html\"><FRAME src=\"blank.html\" NAME=\"USER\"></FRAMESET><BODY BGCOLOR=#FFFFFF></BODY></HTML>";
    [index writeToFile:[NSString stringWithFormat:@"%@/index.html", baseDir] atomically:YES];
        
}



-(NSString *)formatSize:(NSNumber *)number
{
    int koctet = 1024;
    unsigned long   moctet = koctet*1024;
    unsigned long   goctet = moctet*1024;
    unsigned long   toctet = goctet*1024;
    
    
  
    if ([number doubleValue] < 1024){
        return [NSString stringWithFormat:@"%@ Bytes", number];
    }    
    else if (([number doubleValue] >= 1024) && ([number doubleValue] < moctet))
    {
        return [NSString stringWithFormat:@"%.2f KBytes", [[NSNumber numberWithDouble:[number doubleValue]/koctet] doubleValue]];
    }
    else if (([number doubleValue] >= moctet) && ([number doubleValue] < goctet))
    {
        return [NSString stringWithFormat:@"%.2f MBytes", [[NSNumber numberWithDouble:[number doubleValue]/moctet] doubleValue]];
    }
    else if ([number doubleValue] >= goctet)
    {
        return [NSString stringWithFormat:@"%.2f GBytes", [[NSNumber numberWithDouble:[number doubleValue]/goctet] doubleValue]];
    }
    else if ([number doubleValue] >= toctet)
    {
        return [NSString stringWithFormat:@"%.2f TBytes", [[NSNumber numberWithDouble:[number doubleValue]/toctet] doubleValue]];
    }

    
    return nil;
}

- (NSString *) monthName:(NSString *)index
{
    NSString *monthRet = nil;
    
    switch ([index intValue])
    {
        case 0:
            break;
        case 1:
            monthRet = NSLocalizedString(@"January",@"month of january");
            break;
        case 2:
            monthRet = NSLocalizedString(@"February",@"month of February");
            break;
        case 3:
            monthRet = NSLocalizedString(@"March",@"month of March");
            break;
        case 4:
            monthRet = NSLocalizedString(@"April",@"month of April");
            break;
        case 5:
            monthRet = NSLocalizedString(@"May",@"month of May");
            break;
        case 6:
            monthRet = NSLocalizedString(@"June",@"month of June");
            break;
        case 7:
            monthRet = NSLocalizedString(@"July",@"month of July");
            break;
        case 8:
            monthRet = NSLocalizedString(@"August",@"month of August");
            break;
        case 9:
            monthRet = NSLocalizedString(@"September",@"month of September");
            break;
        case 10:
            monthRet = NSLocalizedString(@"October",@"month of November");
            break;
        case 11:
            monthRet = NSLocalizedString(@"November",@"month of November");
            break;
        case 12:
            monthRet = NSLocalizedString(@"December",@"month of December");
            break;
    }
    
    return monthRet;
    
}



@end
