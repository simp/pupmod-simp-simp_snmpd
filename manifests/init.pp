# The simp_snmpd init class
#
# @summary Configures the snmpd daemon. Currently, it only uses v3 USM.
# This module does not configure the snmptrap service.
#
# @param ensure
#   present (default) will install files and packages
#   absent  make sure they are not installed.
# @param manage_client
#   tell puppet snmp to manage client.
#   install the net-simp-utils.  These are command line utilities.
# @param  package_ensure
#   If set to "latest" snmp will try to update to the latest version
#   of the package available, otherwise it will just check it is installed
# @param  version
#   The version of snmp protocol to use.
#   At this time the simp_snmpd profile only manages v3, to configure
#   older versions use the snmp module directly.
# @param  snmp_basedir
#   Base directory for snmp configuration files
# @param logfile
#  Full path to local log file for snmpd
# @param  service_config
#   Location of the snmpd daemon configuration file
# @param  simp_snmpd_dir
#   Directory of *.conf files which include snmpd directives.  Files in this
#   directory are managed by puppet.
# @param include_userdir
#   If set to true the user_snmpd_dir will be created and an include directive for it
#   put in the service_config file.  This will allow users to override values in the service config
#   file or add values that are not included by the interface.
# @param  user_snmpd_dir
#   Directory where users can include *.conf files with snmpd configuration items
#   that will be included.  This directory is not managed by simp.  Users can put
#   additional configurations files in this directory. This directory is only included
#   if include_userdir is set to true.
# @param snmpd_service_ensure
#   Set the snmpd daemon service to stopped or running
# @param snmpd_service_startatboot
#   Start the snmpd service at boot
#
# Trap service parameters
# @param trap_service_ensure
#   Set the snmptrap daemon service to stopped or running
# @param trap_service_startatboot
#   Start the snmptrap service at boot
# @param  trap_service_config
#   Location of the trap configuration file
# @param  user_trapd_dir
#   Directory where users can place snmptrap configuration files.
#   This profile does not configure snmptrap but buts down a configuration file that tells
#   the snmptrap daemon to look in this directory for configuration files.
#   This directory is only created if trap_service_ensure is set to running.
# @param snmptrapd_options
#   Options to pass to the trap daemon on start up.
#
# SNMPD Agent Parameters
# @param snmpd_options
#   The options passed to the snmpd daemon at start up.
#   The default sends info through critical to local6.
# @see man snmpd for options.
# @param agentaddress
# @see man snmpd  in the LISTENING ADDRESSES section for more details.
#   An array of listening addresses for the snmpd to listen on.
#   This array is also used by the config/firewall.pp to open ports if iptables
#   is being used.
# @param do_not_log_tcpwrappers
# @see man snmpd.conf AGENT BEHAVIOR section for more information on the
#   This  setting  disables  the  log  messages  for
#   accepted connections. Denied connections will still be logged.
# @param  maxgetbulkrepeats
#   Sets the maximum number of responses allowed for a single variable in a getbulk request
# @see man snmpd.conf AGENT BEHAVIOR section for more information on the
# @param  maxgetbulkresponses
#  Sets the maximum number of responses allowed for a getbulk request.
# @see man snmpd.conf AGENT BEHAVIOR section for more information on the
# @param  leave_pidfile
#   Leave the pid file when snmpd exits
# @param service_config_perms
#   permissions on the configuration files
# @param service_config_dir_perms
#   permissions on the configuration directories
# @param service_config_dir_owner
#   owner of configuration files/dirs
# @param service_config_dir_group
#   group of configuration files/dirs
# @param manage_snmpd_user
#   Set to true if you want puppet to create the user for config files
# @param manage_snmpd_group
#   Set to true if you want puppet to create the group for config files
# @param  snmpd_uid
#   The uid used when creating the service_config_dir_owner
# @param  snmpd_gid
#   The gid used when creating the service_config_dir_group
#
# Settings for rsync
# @param rsync_server
#   The rsync server from which to pull the files.
# @param rsync_source
#   The source of the content to be rsync' as defined in the rsyncd.conf file on the rsync server.
# @param rsync_timeout
#   The timeout when connecting to the rsync server.
# @param rsync_dlmod
#   Whether to enable rsync to copy dlmod modules to the dlmod directory
# @param rsync_dlmod_dir
#   The full path for the directory to use for dlmod rsync.
# @param dlmods
#   List of modules to load into snmpd from the rsync_dlmod directory
# @param rsync_mibs
#   Whether to enable rsync for MIBS
# @param rsync_mibs_dir
#   The full path for the directory to rsync mibs too.  It does not
#   remove what is already there.
#
# USM/VACM parameters
# @param v3_users_hash
# @see man snmpd.conf  SNMPv3 with the User-based Security Model (USM) section
#   A hash of users to create for usm access. Also see README for details
# @param v3_users_hash
#   hash of users to create for USM.
# @param view_hash
#   Hash of views to create for VACM
# @param group_hash
#   Hash of groups to create for VACM
# @param access_hash
#   Hash of access entrys to create for VACM.
#
# snmp.conf access configuration default items.
# These are also used to set up view and access directives
# if specific settings are not used in the hash.
# @param  defauthtype
#   The default authentication type used for clients.
# @param  defprivtype
#   The default privacy type used for encrypting communication when using usm.
# @param  defsecuritymodel
#   currently simp_snmpd only supports the usm security model.
# @param defsecuritylevel
#   The default security level used by the client
# @param defvacmlevel
#   The default security level for the VACM access directives.
#
# snmpd.conf system info parameters
# If the system parameters are set in the snmpd.conf files net-snmp
# sets them as not writeable and they can not be changed by an 'set' call from
# an snmpd client or manager.  If you want to set them this way the
# change simp_snmpd::system_info to false.
# @param system_info Deprecated (puppet-snmp does not allow you to not set these).
# @param location
#   sets sysLocation in snmp
# @param sysname
#   sets sysName in snmp
# @param contact
#   sets sysContact in snmp
# @param services
#   sets sysServices in snmp
#
# SIMP parameters used
# @param fips
#   If fips should be enabled or not.  Fips mode does not allow MD5 or DES
#   macs/ciphers.
# @param firewall
#   Whether include modules that will use agentaddress array to open ports in
#   iptables.
# @param trusted_nets
#   Networks that will be allowed to access the snmp ports opened by the firewall.
# @param syslog
# @param logrotate
#   If these variables are set then rules will be added to rsyslog to log
#   snmp messages to /var/log/snmpd.log and set up log rotation.
# @param tcpwrappers
#   Whether or not the system is using tcpwrappers to control access.
#
class simp_snmpd (
  Hash                           $v3_users_hash, # See module data
  Hash                           $view_hash,     # See module data
  Hash                           $group_hash,    # See module data
  Hash                           $access_hash,   # See module data
  String                         $snmpd_options,
  Enum['present','absent']       $ensure                    = 'present',
  Integer                        $version                   = 3,
  Enum['stopped', 'running']     $snmpd_service_ensure      = 'running',
  Boolean                        $snmpd_service_startatboot = true,
  Enum['stopped', 'running']     $trap_service_ensure       = 'stopped',
  Boolean                        $trap_service_startatboot  = false,
  Boolean                        $manage_client             = false,
  Enum['yes','no']               $do_not_log_tcpwrappers    = 'no',
  Array[String]                  $agentaddress              = ['udp:127.0.0.1:161'],
  Optional[String]               $snmptrapd_options         = undef,
  StdLib::AbsolutePath           $snmp_basedir              = '/etc/snmp',
  StdLib::AbsolutePath           $trap_service_config       = "${simp_snmpd::snmp_basedir}/snmptrapd.conf",
  StdLib::AbsolutePath           $service_config            = "${simp_snmpd::snmp_basedir}/snmpd.conf",
  StdLib::AbsolutePath           $simp_snmpd_dir            = "${simp_snmpd::snmp_basedir}/simp_snmpd.d",
  StdLib::AbsolutePath           $user_snmpd_dir            = "${simp_snmpd::snmp_basedir}/snmpd.d",
  StdLib::AbsolutePath           $user_trapd_dir            = "${simp_snmpd::snmp_basedir}/snmptrapd.d",
  Stdlib::Filemode               $service_config_perms      = '0600',
  Stdlib::Filemode               $service_config_dir_perms  = '0750',
  String                         $service_config_dir_owner  = 'root',
  String                         $service_config_dir_group  = 'root',
  Boolean                        $include_userdir           = false,
  StdLib::AbsolutePath           $logfile                   = '/var/log/snmpd.log',
  Enum['SHA','MD5']              $defauthtype               = 'SHA',
  Enum['DES', 'AES']             $defprivtype               = 'AES',
  Simp_snmpd::Secmodel           $defsecuritymodel          = 'usm',
  Simp_snmpd::Seclevel           $defsecuritylevel          = 'authPriv',
  Simp_snmpd::Vacmlevel          $defvacmlevel               = 'priv',
  Integer                        $maxgetbulkrepeats         = 100,
  Enum['yes','no']               $leave_pidfile             = 'no',
  Integer                        $maxgetbulkresponses       = 100,
  Boolean                        $system_info               = true,
  String                         $location                  = 'Unknown',
  String                         $contact                   = "root@${facts['fqdn']}",
  Integer                        $services                  = 72,
  String                         $sysname                   = $facts['fqdn'],
  String                         $rsync_source              = "snmp_${::environment}_${facts['os']['name']}",
  Boolean                        $rsync_dlmod               = false,
  Boolean                        $rsync_mibs                = false,
  Optional[StdLib::AbsolutePath] $rsync_dlmod_dir           = '/usr/lib64/snmp',
  Optional[StdLib::AbsolutePath] $rsync_mibs_dir            = '/usr/share/snmp',
  Optional[Array[String]]        $dlmods                    = undef,
  Optional[Integer]              $snmpd_gid                 = undef,
  Optional[Integer]              $snmpd_uid                 = undef,
  Boolean                        $manage_snmpd_user         = false,
  Boolean                        $manage_snmpd_group        = false,
  Simplib::Host                  $rsync_server              = simplib::lookup('simp_options::rsync::server',  { 'default_value' => '127.0.0.1' }),
  Integer                        $rsync_timeout             = simplib::lookup('simp_options::rsync::timeout', { 'default_value' => 2 }),
  Boolean                        $firewall                  = simplib::lookup('simp_options::firewall',       { 'default_value' => false }),
  Boolean                        $tcpwrappers               = simplib::lookup('simp_options::tcpwrappers',    { 'default_value' => false }),
  Boolean                        $syslog                    = simplib::lookup('simp_options::syslog',         { 'default_value' => false }),
  Boolean                        $logrotate                 = simplib::lookup('simp_options::logrotate',      { 'default_value' => false }),
  Boolean                        $fips                      = simplib::lookup('simp_options::fips',           { 'default_value' => false }),
  Simplib::Netlist               $trusted_nets              = simplib::lookup('simp_options::trusted_nets',   { 'default_value' => ['127.0.0.1'] }),
  String                         $package_ensure            = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
) {

  if $simp_snmpd::version == 3 {
    include simp_snmpd::install
    include simp_snmpd::config

    Class['simp_snmpd::install']
    -> Class['simp_snmpd::config']
    ~> Service['snmpd']

    if $rsync_dlmod or $rsync_mibs {
      include simp_snmpd::rsync
      Class['simp_snmpd::config'] -> Class['simp_snmpd::rsync']
    }
  }
  else {
    $msg = "${module_name}: Snmp Version #{simp_snmpd::version} not supported.  This module is only used for snmp version 3 at this time. Try using the puppet-snmp module directly"
    notify{  'net-snmp version': message => $msg}
  }
}
