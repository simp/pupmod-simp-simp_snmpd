# simp_snmpd::config
#
# @summary This class is called from simp_snmp for service config.
#
class simp_snmpd::config {
  assert_private()

  # Create agent setting in agent.conf
  contain simp_snmpd::config::agent

  if $simp_snmpd::firewall {
    include simp_snmpd::config::firewall
  }

  if $simp_snmpd::tcpwrappers {
    include simp_snmpd::config::tcpwrappers
  }

  if $simp_snmpd::syslog {
    include simp_snmpd::config::logging
  }

  $_mibs_dir = $simp_snmpd::rsync_mibs ? {
    true    => $simp_snmpd::rsync_mibs_dir,
    default => '' }

  $_dlmod_dir = $simp_snmpd::rsync_dlmod ? {
    true    => $simp_snmpd::rsync_dlmod_dir,
    default => '' }

  #if the group snmp exists then give it access to snmp directories

  if $simp_snmpd::snmpd_gid {
    exec { 'set_snmp_perms':
      command => "/usr/bin/setfacl -R -m g:snmp:r /etc/snmp ${_dlmod_dir} ${_mibs_dir}",
      onlyif  => '/bin/grep -q "^snmp" /etc/group',
      require => Package['snmpd']
    }
  }
}
