# == Class simp_snmpd::install
#
# -set up snmp group/user if needed
# - (if user and group != root then need to change permissions on
#  directories.
#     /etc/snmp /var/lib/net-snmp
#     (previous snmpd module set acl on these directories.)
#  -set up defaults in snmp.conf?
#  -disable v2 setup
#
class simp_snmpd::install {
  if $simp_snmpd::snmp_gid {
    group { 'snmp':
      ensure => present,
      gid    => $simp_snmpd::snmp_gid,
      system => no
    }
  }

  if $simp_snmpd::snmp_uid {
    user { 'snmp':
      ensure => present,
      uid    => $simp_snmpd::snmp_uid,
      system => no
    }
  }

  # include directories for further configuration
  # lastone wins so put user directory after simp
  # so they can include files to override/change/add to what
  # simp creates.
  $snmpd_config  = [
    "includeDir ${simp_snmpd::simp_snmpd_dir}",
    "includeDir ${simp_snmpd::user_snmpd_dir}"
  ]

  $snmp_config = [
    'includeFile /etc/snmp/snmp.simp.conf'
  ]

  file { '/etc/snmp':
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0750'
  }

  # How to default the agent address?  Will need to
  # open iptables for addresses as well.
  # need to read listening address array and create agent addresses
  $_agentaddress = $simp_snmpd::agentaddress.map | Simp_snmpd::Listeningaddr $addr | {
    $addr.join(':')
  }

  # TODO: determine snmpd_options Logging?
  class { 'snmp':
    agentaddress             => $_agentaddress,
    ensure                   => $simp_snmpd::ensure,
    autoupgrade              => $simp_snmpd::autoupgrade,
    service_ensure           => $simp_snmpd::snmpd_service_ensure,
    service_enable           => $simp_snmpd::snmpd_service_startatboot,
    service_config_dir_group => $simp_snmpd::snmp_gid,
    template_snmpd_conf      => 'simp_snmpd/snmpd/snmpd.conf.erb',
    snmpd_config             => $snmpd_config,
    trap_service_ensure      => $simp_snmpd::trap_service_ensure,
    trap_service_enable      => $simp_snmpd::trap_service_startatboot,
    do_not_log_traps         => $simp_snmpd::do_not_log_traps,
    do_not_log_tcpwrappers   => $simp_snmpd::do_not_log_tcpwrappers,
    manage_client            => $simp_snmpd::manage_client,
    snmp_config              => $snmp_config,
  }
}
