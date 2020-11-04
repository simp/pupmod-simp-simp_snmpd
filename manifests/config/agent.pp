# @summary Set up sensible agent defaults
#
class simp_snmpd::config::agent {

  assert_private()

  file { "${simp_snmpd::simp_snmpd_dir}/agent.conf":
    ensure  => file,
    owner   => $simp_snmpd::service_config_dir_owner,
    group   => $simp_snmpd::service_config_dir_group,
    mode    => $simp_snmpd::service_config_perms,
    require => File[$simp_snmpd::simp_snmpd_dir],
    content => epp("${module_name}/snmpd/agent.conf.epp"),
  }
}
