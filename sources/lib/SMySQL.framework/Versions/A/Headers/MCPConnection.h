//
//  MCPConnection.h
//  SMySQL
//
//  Created by serge cohen (serge.cohen@m4x.org) on Sat Dec 08 2001.
//  Copyright (c) 2001 Serge Cohen.
//
//  This code is free software; you can redistribute it and/or modify it under
//  the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or any later version.
//
//  This code is distributed in the hope that it will be useful, but WITHOUT ANY
//  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
//  FOR A PARTICULAR PURPOSE. See the GNU General Public License for more
//  details.
//
//  For a copy of the GNU General Public License, visit <http://www.gnu.org/> or
//  write to the Free Software Foundation, Inc., 59 Temple Place--Suite 330,
//  Boston, MA 02111-1307, USA.
//
//  More info at <http://mysql-cocoa.sourceforge.net/>
//
// $Id: MCPConnection.h,v 1.5 2003/08/16 14:11:18 sergecohen Exp $
// $Author: sergecohen $


#import <Foundation/Foundation.h>
#import "mysql.h"
#import "SMySQLConstants.h"


@class MCPResult;

// Deafult connection option
extern const unsigned int	kMCPConnectionDefaultOption;

// Default socket (from the mysql.h used at compile time)
extern const char		*kMCPConnectionDefaultSocket;

// Added to mysql error code
extern const unsigned int 	kMCPConnectionNotInited;

@interface MCPConnection : NSObject {
    MYSQL		*mConnection;	/*"The inited MySQL connection"*/
    BOOL		   mConnected;	/*"Reflect the fact that the connection is already in place or not"*/
    NSStringEncoding	mEncoding;	/*"The encoding used by MySQL server, to ISO-1 default"*/
}
/*"
Getting default of MySQL
"*/
+ (NSDictionary *) getMySQLLocales;
+ (NSStringEncoding) encodingForMySQLEncoding:(const char *) mysqlEncoding;
+ (NSStringEncoding) defaultMySQLEncoding;

/*"
Class maintenance
"*/
+ (void) initialize;

/*"
Initialisation
"*/
- (id) init;
// Port to 0 to use the default port
- (id) initToHost:(NSString *) host withLogin:(NSString *) login password:(NSString *) pass usingPort:(int) port;
- (id) initToSocket:(NSString *) socket withLogin:(NSString *) login password:(NSString *) pass;

- (BOOL) setConnectionOption:(int) option withArgument:(id) arg;
// Port to 0 to use the default port
- (BOOL) connectWithLogin:(NSString *) login password:(NSString *) pass host:(NSString *) host port:(int) port socket:(NSString *) socket;

- (BOOL) selectDB:(NSString *) dbName;

/*"
Errors information
"*/

- (NSString *) getLastErrorMessage;
- (unsigned int) getLastErrorID;
- (BOOL) isConnected;
- (BOOL) checkConnection;

/*"
Queries
"*/

- (NSString *) prepareBinaryData:(NSData *) theData;
- (NSString *) prepareString:(NSString *) theString;

- (MCPResult *) queryString:(NSString *) query;

- (my_ulonglong) affectedRows;
- (my_ulonglong) insertId;


/*"
Getting description of the database structure
"*/
- (MCPResult *) listDBs;
- (MCPResult *) listDBsLike:(NSString *) dbsName;
- (MCPResult *) listTables;
- (MCPResult *) listTablesLike:(NSString *) tablesName;
// Next method uses SHOW TABLES FROM db to be sure that the db is not changed during this call.
- (MCPResult *) listTablesFromDB:(NSString *) dbName like:(NSString *) tablesName;
- (MCPResult *) listFieldsFromTable:(NSString *) tableName;
- (MCPResult *) listFieldsFromTable:(NSString *) tableName like:(NSString *) fieldsName;


/*"
Server information and control
"*/

- (NSString *) clientInfo;
- (NSString *) hostInfo;
- (NSString *) serverInfo;
- (NSNumber *) protoInfo;
- (MCPResult *) listProcesses;
- (BOOL) killProcess:(unsigned long) pid;

//- (BOOL)createDBWithName:(NSString *)dbName;
//- (BOOL)dropDBWithName:(NSString *)dbName;

/*"
Disconnection
"*/

- (void) disconnect;
- (void) dealloc;

/*"
String encoding concerns (c string type to NSString).
It's unlikely that users of the framework needs to use these methods which are used internally
"*/
- (void) setEncoding:(NSStringEncoding) theEncoding;
- (NSStringEncoding) encoding;

- (const char *) cStringFromString:(NSString *) theString;
- (NSString *) stringWithCString:(const char *) theCString;

/*"
Text data convertion to string
"*/
- (NSString *) stringWithText:(NSData *) theTextData;

@end
