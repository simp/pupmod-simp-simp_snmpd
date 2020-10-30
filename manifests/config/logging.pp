# simp_snmpd::config::logging
#
# @summary This class is meant to be called from simp_snmp.
# It ensures that logging rules are defined.
#
class simp_snmpd::config::logging {
  assert_private()

  include '::rsyslog'

  rsyslog::rule::local { 'XX_snmpd':
    rule            => '$programname == \'snmpd\'',
    target_log_file => $simp_snmpd::logfile,
    require         => File[$simp_snmpd::logfile],
    stop_processing => true
  }

  if $simp_snmpd::logrotate {
    include '::logrotate'
    logrotate::rule { 'snmpd':
      log_files                 => [ $simp_snmpd::logfile ],
      lastaction_restart_logger => true
    }
  }

  file { $simp_snmpd::logfile:
    owner   => pick($simp_snmpd::snmpd_uid,'root'),
    group   => pick($simp_snmpd::snmpd_gid,'root'),
    mode    => '0640',
    seltype => 'snmpd_log_t',
  }

}
