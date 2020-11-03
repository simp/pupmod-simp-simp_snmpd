# simp_snmpd::install::snmpdusers
#
# @summary Create systems users for running snmpd daemon
#    and owning the snmpd files
#
class simp_snmpd::install::snmpduser{

  assert_private()

  if $simp_snmpd::manage_snmpd_user {
    if $simp_snmpd::service_config_dir_owner != 'root' {
      user { $simp_snmpd::service_config_dir_owner:
        ensure => present,
        uid    => $simp_snmpd::snmpd_uid,
        system => 'no'
      }
    }
  }
  if $simp_snmpd::manage_snmpd_group {
    if $simp_snmpd::service_config_dir_group != 'root' {
      group { $simp_snmpd::service_config_dir_owner:
        ensure => present,
        gid    => $simp_snmpd::snmpd_gid,
        system => 'no'
      }
    }
  }
}
