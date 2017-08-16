# simp_snmpd::config::system_info
#
# @summary This sets up some defaults for the agent.
#
class simp_snmpd::config::system_info {

  file { "${simp_snmpd::simp_snmpd_dir}/system_info.conf":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0750',
    require => File[$simp_snmpd::simp_snmpd_dir],
    content => epp("${module_name}/snmpd/system_info.conf.epp"),
  }

}
