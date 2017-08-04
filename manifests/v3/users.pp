# Create v3 users from user hash
class simp_snmpd::v3::users(
  Enum['snmpd','snmptrapd'] $daemon = 'snmpd'
){

  $simp_snmpd::v3_users_hash.each |String $username,  Optional[Hash] $settings| {
    if $settings {
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
