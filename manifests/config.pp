# == Class simp_snmpd::config
#
# This class is called from simp_snmp for service config.
#
class simp_snmpd::config {
  assert_private()

  if $simp_snmpd::firewall {
    include simp_snmpd::config::firewall
  }

  if $simp_snmpd::tcpwrappers {
    include simp_snmpd::config::tcpwrappers
  }

  if $simp_snmpd::syslog {
    include simp_snmpd::config::logging
  }

  file { [ $simp_snmpd::simp_snmpd_dir, $simp_snmpd::user_snmpd_dir ]:
    ensure => directory,
    owner  => root,
    group  => root,
    mode   => '0750',
  }

  # Copied this from old simp snmpd module...why does it need
  # package net-snmp-utils?  I changed it to package net-snmp
  # if running snmp under a different group make it has read permissions on
  # the configuration files.

  $_mibs_dir = $simp_snmpd::rsync_mibs ? {
    true    => $simp_snmpd::rsync_mibs_dir,
    default => '' }

  $_dlmod_dir = $simp_snmpd::rsync_dlmod ? {
    true    => $simp_snmpd::rsync_dlmod_dir,
    default => '' }

  exec { 'set_snmp_perms':
    command => "/usr/bin/setfacl -R -m g:snmp:r /etc/snmp ${_dlmod_dir} ${_mibs_dir}",
    onlyif  => '/bin/grep -q "^snmp" /etc/group',
    #    require => Package['net-snmp-utils']
    require => Package['snmpd']
  }

}
