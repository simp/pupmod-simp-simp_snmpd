# simp_snmpd::config
#
# @summary This class is called from simp_snmp for service config.
#
class simp_snmpd::config {
  assert_private()

  # Set up access control in the access.conf file
  case $simp_snmpd::defsecuritymodel {
    'usm':  { contain simp_snmpd::config::usm }
    default: {
      $msg = "The following Security model is not supported by simp_snmpd at this time: ${simp_snmpd::defsecuritymodel}.  Access will not be configured. "
      notify {'simp_snmpd Security Model':
        message => $msg
      }
    }
  }

  # Create agent setting in agent.conf
  contain simp_snmpd::config::agent

  if $simp_snmpd::system_info {
    include simp_snmpd::config::system_info
  }

  if $simp_snmpd::firewall {
    include simp_snmpd::config::firewall
  }

  if $simp_snmpd::tcpwrappers {
    include simp_snmpd::config::tcpwrappers
  }

  if $simp_snmpd::syslog {
    include simp_snmpd::config::logging
  }

  file { [ $simp_snmpd::simp_snmpd_dir, $simp_snmpd::user_snmpd_dir, $simp_snmpd::user_trapd_dir]:
    ensure => directory,
    owner  => 'root',
    group  => 'root',
    mode   => '0750',
  }

  $_mibs_dir = $simp_snmpd::rsync_mibs ? {
    true    => $simp_snmpd::rsync_mibs_dir,
    default => '' }

  $_dlmod_dir = $simp_snmpd::rsync_dlmod ? {
    true    => $simp_snmpd::rsync_dlmod_dir,
    default => '' }

  exec { 'set_snmp_perms':
    command => "/usr/bin/setfacl -R -m g:snmp:r /etc/snmp ${_dlmod_dir} ${_mibs_dir}",
    onlyif  => '/bin/grep -q "^snmp" /etc/group',
    require => Package['snmpd']
  }

}
