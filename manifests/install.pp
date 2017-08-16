# simp_snmpd::install
#
# @summary Set up snmp group/user if needed, and subsequently change
# permissions.  Set defaults in snmp.conf.  Disable v2 setup.
#
class simp_snmpd::install {

  if $simp_snmpd::snmpd_gid {
    group { 'snmp':
      ensure => present,
      gid    => $simp_snmpd::snmpd_gid,
      system => 'no'
    }
  }

  if $simp_snmpd::snmpd_uid {
    user { 'snmp':
      ensure => present,
      uid    => $simp_snmpd::snmpd_uid,
      system => 'no'
    }
  }

  # Include directories for further configuration.  The last one wins, so put
  # user directory after simp, so they can include files to override, change,
  # and add to what simp creates.
  $_snmpd_config  = [
    "includeDir ${simp_snmpd::simp_snmpd_dir}",
    "includeDir ${simp_snmpd::user_snmpd_dir}"
  ]

  $_snmptrapd_config = [
    "includeDir ${simp_snmpd::user_trapd_dir}"
  ]

  if $simp_snmpd::manage_client {
    include 'simp_snmpd::install::client'
  }
  else {
    # For some reason the snmp module only creates this directory if the
    # client is included.
    file { '/etc/snmp':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0750'
    }
  }

  $_snmp_config = [
    "includeFile ${simp_snmpd::snmp_conf_file}"
  ]

  $_autoupgrade =  $simp_snmpd::package_ensure ? {
    'latest' => true,
    default  => false
  }

  # TODO: determine snmpd_options Logging?
  class { 'snmp':
    agentaddress             => $simp_snmpd::agentaddress,
    ensure                   => $simp_snmpd::ensure,
    autoupgrade              => $_autoupgrade,
    service_ensure           => $simp_snmpd::snmpd_service_ensure,
    service_enable           => $simp_snmpd::snmpd_service_startatboot,
    service_config_dir_group => 'root',
    service_config_perms     => '0750',
    template_snmpd_conf      => 'simp_snmpd/snmpd/snmpd.conf.erb',
    template_snmptrapd       => 'simp_snmpd/snmptrapd/snmptrapd.conf.erb',
    snmpd_config             => $_snmpd_config,
    snmptrapd_config         => $_snmptrapd_config,
    trap_service_ensure      => $simp_snmpd::trap_service_ensure,
    trap_service_enable      => $simp_snmpd::trap_service_startatboot,
    do_not_log_traps         => $simp_snmpd::do_not_log_traps,
    do_not_log_tcpwrappers   => $simp_snmpd::do_not_log_tcpwrappers,
    manage_client            => $simp_snmpd::manage_client,
    snmp_config              => $_snmp_config,
  }

}
