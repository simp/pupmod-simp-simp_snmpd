# simp_snmpd::install:: client
#
# @summary Sets up parameters to pass to snmp module
# for configuring the snmp.conf file.
#
# The snmp.conf file is used by client utilities
#
#
class simp_snmpd::install::client {

  case $simp_snmpd::defsecuritylevel {
    'priv':   { $seclevel = 'authPriv'}
    'auth':   { $seclevel = 'authNoPriv'}
    'noauth': { $seclevel = 'noAuthNoPriv'}
    default:  { $seclevel = 'authPriv'}
  }

  file { $simp_snmpd::snmp_conf_file :
    owner   => 'root',
    group   => 'root',
    mode    => '0640',
    content => epp("${module_name}/snmpd/snmp_conf.epp")
  }

}

