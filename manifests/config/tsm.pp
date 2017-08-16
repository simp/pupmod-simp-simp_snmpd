# simp_snmpd::config::tsm
#
# @summary This class configures snmpd to use tsm security model.
#
class simp_snmpd::config::tsm {
  assert_private()

  if versioncmp($facts['net_snmp_version'],'5.6.0') >= 0 {
    if $simp_snmpd::pki {
      include 'pki'
      pki::copy { 'snmpd':
        source => $simp_snmpd::app_pki_external_source,
        notify => Service['snmpd'],
        pki    => $simp_snmpd::pki
      }
    }

    if $simp_snmpd::fips or $facts['fips_enabled'] {
      $_ciphers = $simp_snmpd::fips_tls_cipher_suite
    }
    else {
      $_ciphers  = $simp_snmpd::tls_cipher_suite
    }

    $_trustcert = $simp_snmpd::app_pki_cacert

    $_localcert = $simp_snmpd::app_pki_cert

    $_tsmreadfp = $simp_snmpd::tsmreadfp ? {
      false   => 'SIMP_SNMPD_FIGERPRINT_NOT_DEFINED',
      default => $simp_snmpd::tsmreadfp
    }
    $_tsmwritefp = $simp_snmpd::tsmwritefp ? {
      false   => 'SIMP_SNMPD_FIGERPRINT_NOT_DEFINED',
      default => $simp_snmpd::tsmwritefp
    }

    $_tsmreaduser = $simp_snmpd::tsmreaduser
    $_tsmwriteuser = $simp_snmpd::tsmwriteuser

    file { "${simp_snmpd::simp_snmpd_dir}/access_tsm.conf":
      ensure  => file,
      owner   => 'root',
      group   => 'root',
      mode    => '0750',
      require => File[$simp_snmpd::simp_snmpd_dir],
      content => template("${module_name}/snmpd/access_tsm.conf.erb"),
    }
  }
  # The wrong version. TLS is only implemented in net-simp versions 5.6 and later.
  else {
    $msg = "${module_name}: TLS does not work in net-snmp versions before 5.6"
    notify{  'net-snmp version': message => $msg}
  }
}
