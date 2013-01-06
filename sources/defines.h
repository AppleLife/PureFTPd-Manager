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


/* PureFTPd Manager Global definitions */

/* Files */
#define PureFTPPreferenceFile @"/etc/pure-ftpd/pure-ftpd.plist"
#define PureFTPPIDFile @"/var/run/pure-ftpd.pid"
#define PureFTPConfDir @"/etc/pure-ftpd"
#define PureFTPStatsFile @"/var/log/FTPStats.plist"
#define PureFTPDefaultLogFile @"/var/log/ftp.log"
#define PureFTPSSLCertificate @"/etc/pure-ftpd/ssl/pure-ftpd.pem"
#define PureFTPDirAliases @"/etc/pure-ftpd/pureftpd-dir-aliases"

/* Commands */
#define PureFTPWho @"/usr/local/sbin/pure-ftpwho"
#define PureFTPDCMD @"/usr/local/sbin/pure-ftpd"

/* Preferences */
/* General */
#define PureFTPPort @"PureFTPPort"
#define PureFTPTimeout @"PureFTPTimeout"
#define PureFTPPassiveRange @"PureFTPPassiveRange"
#define PureFTPTimeout @"PureFTPTimeout"
#define PureFTPFXP @"PureFTPFXP"
#define PureFTPMaxUsers @"PureFTPMaxUsers"
#define PureFTPMaxSessions @"PureFTPMaxSessions"
#define PureFTPResolvName @"PureFTPResolvName"
#define PureFTPForceActive @"PureFTPForceActive"
#define PureFTPForceIP @"PureFTPForceIP"
#define PureFTPMaxPartition @"PureFTPMaxPartition"
#define PureFTPMaxLoad @"PureFTPMaxLoad"
#define PureFTPUserSpeedLimit @"PureFTPUserSpeedLimit"
#define PureFTPTLSBehaviour @"PureFTPTLSBehaviour"
#define PureFTPAutoUpdateStatus @"PureFTPAutoUpdateStatus"
/*LOG and stats */
#define PureFTPLogOnOff @"PureFTPLogOnOff"
#define PureFTPLogAutoUpdate @"PureFTPLogAutoUpdate"
#define PureFTPLogFormat @"PureFTPLogFormat"
#define PureFTPLogNiceThread @"PureFTPLogNiceThread"
#define PureFTPLogLocation @"PureFTPLogLocation"
#define CLF_PATTERN @"([^ ]+) - ([^ ]+) \\[(.{2})/(.{3})/(.{4}):(.{2}):(.{2}):(.{2}) (.{5})\\] \"(.{3}) (.+)\" .{3} (.+)"
#define W3C_PATTERN @"([^ ]+) ([^ ]+) ([^ ]+) .{2}([^ ]+) (.+) 226 ([^ ]+) ([^ ]+)"
#define LASTLINE @"LastLineLimit"
//#define STATS_PATTERN @""
// #define LOG_PATTERN

/*Authentication*/
#define PureFTPMySQLCrypt @"PureFTPMySQLCrypt"

#define PureFTPMySQLFile @"/etc/pure-ftpd/pureftpd-mysql.conf"
#define PureFTPMySQLHost @"PureFTPMySQLHost"
#define PureFTPMySQLPort @"PureFTPMySQLPort"
#define PureFTPMySQLDatabase @"PureFTPMySQLDatabase"
#define PureFTPMySQLUsername @"PureFTPMySQLUsername"
#define PureFTPMySQLPassword @"PureFTPMySQLPassword"
#define PureFTPMySQLUseDefaultID @"PureFTPMySQLUseDefaultID"
#define PureFTPMySQLDefaultUID @"PureFTPMySQLDefaultUID"
#define PureFTPMySQLDefaultGID @"PureFTPMySQLDefaultGID"

#define PureFTPMySQLUseTrans @"PureFTPMySQLUseTrans"



/* More ... */
#define PureFTPExtraArguments @"PureFTPExtraArguments"

/* Users */
#define PureFTPAuthentificationMethods @"PureFTPAuthentificationMethods"
#define PureFTPCreateHomeDir @"PureFTPCreateHomeDir"
#define PureFTPNoAnonymous @"PureFTPNoAnonymous"
#define PureFTPAnonymousCreateDir @"PureFTPAnonymousCreateDir"
#define PureFTPAnonymousNoUpload @"PureFTPAnonymousNoUpload"
#define PureFTPAnonymousNoDownload @"PureFTPAnonymousNoDownload"
#define PureFTPAnonymousRatio @"PureFTPAnonymousRatio"
#define PureFTPAnonymousSpeedLimit @"PureFTPAnonymousSpeedLimit"

/* Mac OS X */
#define PureFTPAtStartup @"PureFTPAtStartup"
#define PureFTPServerMode @"PureFTPServerMode"
#define PureFTPServerModeModified @"PureFTPServerModeModified"
#define PureFTPAutoUpdate @"PureFTPAutoUpdate"
#define PureFTPRendezVous @"PureFTPRendezVous"
#define PureFTPUserBaseDir @"PureFTPUserBaseDir"
#define PureFTPVHostBaseDir @"PureFTPVHostBaseDir"
#define OSVersion @"OSVersion"

/*Permission Pane*/
#define PureFTPFileCreationMask @"PureFTPFileCreationMask"
#define PureFTPFolderCreationMask @"PureFTPFolderCreationMask"
#define PureFTPCheckVFolderPerm @"PureFTPCheckVFolderPerm"
#define PureFTPShowVFolderConsole @"PureFTPShowVFolderConsole"


/* Virtual hosts */
#define PureFTPVirtualHosts @"PureFTPVirtualHosts"


#define PureFTPPrefsUpdated @"PureFTPPrefsUpdated"
#define PureFTPPreferencesVersion @"PureFTPPreferencesVersion"
#define UPDATE @"1"
#define ENDUPDATE @"0"


#define PureFTPActiveUser @"PureFTPActiveUser"
