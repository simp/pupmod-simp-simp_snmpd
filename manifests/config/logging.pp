# == Class simp_snmpd::config::logging
#
# This class is meant to be called from simp_snmp.
# It ensures that logging rules are defined.
#
class simp_snmpd::config::logging {
  assert_private()

  include '::rsyslog'
  rsyslog::rule::local { 'XX_snmpd':
    rule            => '$programname == \'snmpd\'',
    target_log_file => '/var/log/snmpd.log',
    stop_processing => true
  }
  if $simp_snmpd::logrotate {
    include '::logrotate'
    logrotate::rule { 'snmpd':
      log_files                 => [ '/var/log/snmpd.log' ],
      lastaction_restart_logger => true
    }
  }

  file { '/var/log/snmpd.log':
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    seltype => snmpd_log_t,
  }

}
