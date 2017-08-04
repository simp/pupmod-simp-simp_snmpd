# This file process the user, group, view and access hashes
# It will create the v3 users and place the access information
# in the simp snmpd dir.
# It uses the VACM  rules for snmpd.conf to create the
# groups and view
# It uses the Type rule, (authaccess) to create the access rule.
class simp_snmpd::config::usm {

  $_viewlist = simp_snmpd::viewlist($simp_snmpd::view_hash)
  $_grouplist = simp_snmpd::grouplist($simp_snmpd::group_hash,$simp_snmpd::defsecuritymodel)
  $_accesslist = simp_snmpd::accesslist($simp_snmpd::access_hash,$simp_snmpd::defsecuritymodel,$simp_snmpd::defsecuritylevel)

  file { "${simp_snmpd::simp_snmpd_dir}/access_usm.conf":
    ensure  => file,
    owner   => 'root',
    group   => root,
    mode    => '0750',
    require => File[$simp_snmpd::simp_snmpd_dir],
    content => template("${module_name}/snmpd/access_usm.conf.erb"),
  }

  if $simp_snmpd::version == 3 {
    class { 'simp_snmpd::v3::users' :
      daemon => 'snmpd'
    }
  }

}
