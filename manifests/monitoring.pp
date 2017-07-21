# space holder for default monitoring.
class simp_snmpd::monitoring
{
  $snmpd_monitoring = '#Monitoring stuff in here'

  file { "${simp_snmpd::simp_snmpd_dir}/monitoring.conf":
    ensure  => file,
    owner   => root,
    group   => root,
    mode    => '0640',
    require => File[$simp_snmpd::simp_snmpd_dir],
    content => $snmpd_monitoring,
    notify  => Service['snmpd']
  }

}
