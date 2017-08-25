# simp_snmpd::v3::users
#
# @summary Create v3 users from user hash
#
# @param daemon
#   The daemon that the users is meant to access.
class simp_snmpd::v3::users(
  Enum['snmpd','snmptrapd'] $daemon = 'snmpd'
){

  $simp_snmpd::v3_users_hash.each |String $username,  Optional[Hash] $settings| {
    if  $settings {
      $_authpass = $settings['authpass'] ? {
        /(undef|UNDEF)/  => passgen("snmp_auth_${username}"),
        undef            => passgen("snmp_auth_${username}"),
        default          => $settings['authpass'] }
      $_privpass = $settings['privpass'] ? {
        /(undef|UNDEF)/ => passgen("snmp_priv_${username}"),
        undef           => passgen("snmp_priv_${username}"),
        default         => $settings['privpass'] }
      $_authtype =  $settings['authtype'] ? {
        undef   => $simp_snmpd::defauthtype,
        default => $settings['authtype'] }
      $_privtype =  $settings['privtype'] ? {
        undef   => $simp_snmpd::defprivtype,
        default => $settings['privtype'] }

      if $simp_snmpd::fips or $facts['fips_enabled'] {
        if $_authtype == 'MD5' {
          fail("simp_snmpd:  failed to create user ${username}.  Fips is enabled and authtype is set to 'MD5'.  You must use 'SHA'")
        }
        if $_privtype == 'DES' {
          fail("simp_snmpd:  failed to create user ${username}.  Fips is enabled and privtype is set to 'DES'.  You must use 'AES'")
        }
      }

      snmp::snmpv3_user{ $username:
        authpass =>  $_authpass,
        authtype =>  $_authtype,
        privtype =>  $_privtype,
        privpass =>  $_privpass,
        daemon   =>  $daemon
      }
    }
  }
}
