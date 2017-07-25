# Enter documentation here
# Parameters
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
#   At this time the simp_profile only manages v3, to configure
#   older versions use the snmp module directly.
# @param $v3_users_hash,  $view_hash, $group_hash, $access_hash,
#   These are hashed used to set up access to snmpd.  See
#   the access.pp module for more information.
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
# @param agentaddress
#   An array of listening addresses for the snmpd to listen on. Each
#   element of the array is an array of the form
#   [ Protocol, Address, Port ].
#
#   The addresses to have the snmpd listen on.

class simp_snmpd (
  Enum['present','absent']             $ensure,
  Integer[3,3]                         $version,
  #  Boolean                           $snmptrapd, Just set to false in the snmp call.
  #  Boolean                           $snmpd,   Just set to true in the snmp call.
  Enum['stopped', 'running']           $snmpd_service_ensure,
  Boolean                              $snmpd_service_startatboot,
  Enum['stopped', 'running']           $trap_service_ensure,
  Boolean                              $trap_service_startatboot,
  Boolean                              $manage_client,
  Boolean                              $autoupgrade,
  Enum['yes','no']                     $do_not_log_traps,
  Enum['yes','no']                     $do_not_log_tcpwrappers,
  Hash                                 $v3_users_hash,
  Hash                                 $view_hash,
  Hash                                 $group_hash,
  Hash                                 $access_hash,
  Optional[Array[
    Simp_snmpd::Listeningaddr]]        $agentaddress,
  StdLib::AbsolutePath                 $snmp_conf_file,
  StdLib::AbsolutePath                 $simp_snmpd_dir,
  StdLib::AbsolutePath                 $user_snmpd_dir,
# Do we need to set these?
  Enum['SHA','MD5']                    $defauthtype,
  Enum['DES', 'AES']                   $defprivtype,
  Simp_snmpd::Secmodel                 $defsecuritymodel,
  Enum['auth','noAuth','priv']         $defsecuritylevel,
  Boolean                              $rsync_dlmod,
  Boolean                              $rsync_mibs,
  Optional[StdLib::AbsolutePath]       $rsync_dlmod_dir,
  Optional[StdLib::AbsolutePath]       $rsync_mibs_dir,
  Optional[Integer]                    $snmp_gid           = undef,
  Optional[Integer]                    $snmp_uid           = undef,
  String                               $rsync_source       = "snmpd_${::environment}_${facts['os']['name']}",
  Simplib::Host                        $rsync_server       = simplib::lookup('simp_options::rsync::server',  { 'default_value' => '127.0.0.1'}),
  Integer                              $rsync_timeout      = simplib::lookup('simp_options::rsync::timeout', { 'default_value' => 2 }),
  Boolean                              $firewall           = simplib::lookup('simp_options::firewall',       { 'default_value' => false }),
  Boolean                              $tcpwrappers        = simplib::lookup('simp_options::tcpwrappers',    { 'default_value' => false }),
  Boolean                              $syslog             = simplib::lookup('simp_options::syslog',         { 'default_value' => false }),
  Boolean                              $logrotate          = simplib::lookup('simp_options::logrotate',      { 'default_value' => false }),
  Simplib::Netlist                     $trusted_nets       = simplib::lookup('simp_options::trusted_nets',   { 'default_value' => ['127.0.0.1'] })
) {

  include simp_snmpd::install
  include simp_snmpd::config
  include simp_snmpd::access

  Class['simp_snmpd::install'] -> Class['simp_snmpd::config'] -> Class['simp_snmpd::access']
}
