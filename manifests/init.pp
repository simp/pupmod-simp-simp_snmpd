# The simp_snmpd init class
#
# @summary Configures the snmpd daemon. Currently, it only uses v3 USM.
# This module does not configure the snmptrap service.
#
# @param ensure
#   present (default) will install files and packages
#   absent  make sure they are not installed.
# @param manage_client
#   True = install the net-simp-utils.  These are command line utilities.
# @param  $autoupgrade
#   if true packages will be installed with "latest"
#   if false packages will be installed with "present"
# @param  $version
#   The version of snmp protocol to use.
#   At this time the simp_snmpd profile only manages v3, to configure
#   older versions use the snmp module directly.
# @param  $snmp_conf_file,
#   A file of snmp.conf directives that is included for configuration directives.
#   this file is managed by puppet.
# @param  $simp_snmpd_dir,
#   a directory of *.conf files which include snmpd directives.  Files in this
#   directory are managed by puppet.
# @param  $user_snmpd_dir,
#   a directory where users can include *.conf with snmpd configuration items
#   that will be included.  This directory is not managed by simp.  Users can put
#   additional configurations files in this directory.
# @param   $snmpd_service_ensure, $trap_service_ensure
#   Set the snmpd/trap daemon service to stopped or running
# @param $snmpd_service_startatboot, $trap_service_startatboot
#   Start the snmpd/trap service at boot
#
# SNMPD Agent Parameters
# @param agentaddress
# @see man snmpd  in the LISTENING ADDRESSES section for more details.
#   An array of listening addresses for the snmpd to listen on. Each
#   element of the array is an array of the form.  This array is
#   also used by the config/firewall.pp to open ports if iptables
#   is being used.
#   following:
# @params $do_not_log_tcpwrappers
# @see man snmpd.conf AGENT BEHAVIOR section for more information on the
#   Turn on or off snmpd logging of tcpwrappers
# @params  $maxgetbulkrepeats,
# @see man snmpd.conf AGENT BEHAVIOR section for more information on the
# @params  $maxgetbulkresponses,
# @see man snmpd.conf AGENT BEHAVIOR section for more information on the
# @params  $leave_pidfile,
#   Leave the pid file when snmpd exits
# @params  $snmpd_gid
#   The group id to change the snmpd to run under.  It will create group snmp
#   with that group if this is set.
#
#
# @param $rsync_dlmod
#   Whether to enable rsync to copy dlmod modules to the dlmod directory
# @param $rsync_dlmod_dir
#   The full path for the directory to use for dlmod rsync.
# @param $dlmods
#   List of modules to load into snmpd from the rsync_dlmod directory
# @param $rsync_mibs
#   Whether to enable rsync for MIBS
# @param $rsync_mibs_dir
#  The full path for the directory to rsync mibs too.  It does not
#  remove what is already there.
#
# USM/VACM parameters
# @params v3_users_hash
# @see man snmpd.conf  SNMPv3 with the User-based Security Model (USM) section
#   A hash of users to create for usm access. Also see README for details
# @param $v3_users_hash,  $view_hash, $group_hash, $access_hash,
#   These are hashes used to set up access to snmpd.  See
#   the access_usm.pp module for more information.
# @param $simp_snmp_file
#   file to hold snmp configuration directives for client utils.
# @param $simp_snmpd_dir
#   Directory to hold configuration files defined by simp and used
#   by the snmpd daemon.  These files are managed by puppet.
# @param $user_snmpd_dir
#   Directory to hold additional configuration files created by user.
#   These files are not managed by puppet.  For settings that are
#   one off (and not cumulative like groups or access) the last one wins.
#   This diretory is read after the simp_snmpd directory and will
#   override those settings.
#
# snmp.conf access configuration default items
# @param  $defauthtype,
#   The default authentication type used for clients.
# @param  $defprivtype,
#   The default privacy type used for encrypting communication when using usm.
# @param  $defsecuritymodel,
#   currently simp_snmpd only supports the usm security model it will support
#   tsm  in the near future.  This option determins if usm or tsm access is
#   configured.
# @param $defsecuritylevel
#   The default security level used by the client and to set up usm users.
#
# snmpd.conf system info parameters
# If the system parameters are set in the snmpd.conf files net-snmp
# sets them as not writeable and they can not be changed by an 'set' call from
# an snmpd client or manager.  If you want to set them this way the
# change $simp_snmpd::set_system_info to false.
# @param $set_system_info
#   If true it will set the contact, location, name and services parameters from the
#   following hiera varaiables:
# @param $location
#   sets sysLocation in snmp
# @param $sysname
#   sets sysName in snmp
# @param $contact
#   sets sysContact in snmp
# @param $services
#   sets sysServices in snmp
#
# SIMP parameters used
# @param $firewall
#   Whether include modules that will use agentaddress array to open ports in
#   iptables.
# @param $trusted_nets
#   Networks that will be allowed to access the snmp ports opened by the firewall.
# @param $syslog, $logrotate
#   The snmp module configure snmp to log to the system log using the daemon.
#   If these variables are set then rules will be added to rsyslog to log
#   snmp messages to /var/log/snmpd.log and set up log rotation.
# @params $tcpwrappers
#   Whether or not the system is using tcpwrappers to control access.
#
class simp_snmpd (
  Enum['present','absent']             $ensure,
  Integer                              $version,
  Enum['stopped', 'running']           $snmpd_service_ensure,
  Boolean                              $snmpd_service_startatboot,
  Enum['stopped', 'running']           $trap_service_ensure,
  Boolean                              $trap_service_startatboot,
  Boolean                              $manage_client,
  Enum['yes','no']                     $do_not_log_traps,
  Enum['yes','no']                     $do_not_log_tcpwrappers,
  Hash                                 $v3_users_hash,
  Hash                                 $view_hash,
  Hash                                 $group_hash,
  Hash                                 $access_hash,
  Array[String]                        $agentaddress,
  StdLib::AbsolutePath                 $snmp_conf_file,
  StdLib::AbsolutePath                 $simp_snmpd_dir,
  StdLib::AbsolutePath                 $user_snmpd_dir,
  StdLib::AbsolutePath                 $user_trapd_dir,
  Enum['SHA','MD5']                    $defauthtype,
  Enum['DES', 'AES']                   $defprivtype,
  Simp_snmpd::Secmodel                 $defsecuritymodel,
  Simp_snmpd::Auth                     $defsecuritylevel,
  Integer                              $maxgetbulkrepeats,
  Enum['yes','no']                     $leave_pidfile,
  Integer                              $maxgetbulkresponses,
  Boolean                              $system_info,
  String                               $location,
  String                               $contact,
  String                               $services,
  String                               $sysname,
  String                               $rsync_source,
  Boolean                              $rsync_dlmod,
  Boolean                              $rsync_mibs,
  Optional[StdLib::AbsolutePath]       $rsync_dlmod_dir,
  Optional[StdLib::AbsolutePath]       $rsync_mibs_dir,
  Optional[Array[String]]              $dlmods                  = undef,
  Optional[Integer]                    $snmpd_gid               = undef,
  Optional[Integer]                    $snmpd_uid               = undef,
  Simplib::Host                        $rsync_server            = simplib::lookup('simp_options::rsync::server',  { 'default_value' => '127.0.0.1' }),
  Integer                              $rsync_timeout           = simplib::lookup('simp_options::rsync::timeout', { 'default_value' => 2 }),
  Boolean                              $firewall                = simplib::lookup('simp_options::firewall',       { 'default_value' => false }),
  Boolean                              $tcpwrappers             = simplib::lookup('simp_options::tcpwrappers',    { 'default_value' => false }),
  Boolean                              $syslog                  = simplib::lookup('simp_options::syslog',         { 'default_value' => false }),
  Boolean                              $logrotate               = simplib::lookup('simp_options::logrotate',      { 'default_value' => false }),
  Boolean                              $fips                    = simplib::lookup('simp_options::fips',           { 'default_value' => false }),
  Simplib::Netlist                     $trusted_nets            = simplib::lookup('simp_options::trusted_nets',   { 'default_value' => ['127.0.0.1'] }),
  Variant[Enum['simp'],Boolean]        $pki                     = simplib::lookup('simp_options::pki',            { 'default_value' => false }),
  String                               $package_ensure          = simplib::lookup('simp_options::package_ensure', { 'default_value' => 'installed' }),
  Optional[String]                     $tsmreadfp               = undef,
  Optional[String]                     $tsmwritefp              = undef,
  Optional[String]                     $tsmreaduser             = undef,
  Optional[String]                     $tsmwriteuser            = undef,
  Stdlib::Absolutepath                 $app_pki_dir             = '/etc/pki/simp_apps/snmpd/x509',
  Stdlib::Absolutepath                 $app_pki_external_source = simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/pki/simp/x509' }),
  Stdlib::Absolutepath                 $app_pki_cert            = "${app_pki_dir}/public/${facts['fqdn']}.pub",
  Stdlib::Absolutepath                 $app_pki_key             = "${app_pki_dir}/private/${facts['fqdn']}.pem",
  Stdlib::Absolutepath                 $app_pki_cacert          = "${app_pki_dir}/cacerts/cacerts.pem",
  Array[String]                        $tls_cipher_suite        = simplib::lookup('simp_options::openssl::cipher_suite', { 'default_value' => ['DEFAULT','!MEDIUM'] })
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
    $msg = "${module_name}: Snmp Version #{simp_snmpd::version} not supported.  This module is only used for snmp version 3."
    notify{  'net-snmp version': message => $msg}
  }
}
