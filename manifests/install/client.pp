# == Class simp_snmpd::install:: client
#
# Sets up parameters to pass to snmp module
# for configuring the snmp.conf file.
#
# The snmp.conf file is used by client utilities
# 
#
class simp_snmpd::install::client {

  case $simp_snmpd::defsecuritylevel {
          'priv': { $seclevel = 'authPriv'}
          'auth': { $seclevel = 'authNoPriv'}
          'noauth': {$seclevel = 'noAuthNOPriv'}
          default: { $seclevel = 'authPriv'}
  }

  $snmp_config = [
    "includeDir ${simp_snmpd::snmp_conf_dir}",
    "defVersion ${simp_snmpd::version}",
    "defSecurityModel ${simp_snmpd::defsecuritymodel}",
    "defSecurityLevel ${seclevel}",
    "defAuthType ${simp_snmp::defauthtype}",
    "defPrivType ${simp_snmp::defprivtype}",
    "mibsdir /usr/share/snmpd/mibs:${simp_snmpd::rsync_mibs_dir}/mibs"
  ]

}

