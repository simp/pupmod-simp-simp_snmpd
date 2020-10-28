# simp_snmpd::install
#
# @summary Set up snmp group/user if needed, and subsequently change
# permissions.  Set defaults in snmp.conf.  Disable v2 setup.
#
class simp_snmpd::install {

  if $simp_snmpd::snmpd_gid {
    group { 'snmp':
      ensure => present,
      gid    => $simp_snmpd::snmpd_gid,
      system => 'no'
    }
  }

  if $simp_snmpd::snmpd_uid {
    user { 'snmp':
      ensure => present,
      uid    => $simp_snmpd::snmpd_uid,
      system => 'no'
    }
  }

# Check if default types are appropriate for fips mode if it is being used.
  if $simp_snmpd::fips or $facts['fips_enabled'] {
    if $simp_snmpd::defauthtype == 'MD5' {
      fail("simp_snmpd:  Invalid default authentication type (simp_snmpd::defauthtype): ${simp_snmpd::defauthtype} for use in fips mode.")
    }
    if $simp_snmpd::defprivtype == 'DES' {
      fail("simp_snmpd:  Invalid default privacy type (simp_snmpd::defprivtype): ${simp_snmpd::defprivtype} for use in fips mode.")
    }
  }


  # Include directories for further configuration.  The last one wins, so put
  # user directory after simp, so they can include files to override, change,
  # and add to what simp creates.
  $_snmpd_config  = [
    "includeDir ${simp_snmpd::simp_snmpd_dir}",
    "includeDir ${simp_snmpd::user_snmpd_dir}"
  ]

  $_snmptrapd_config = [
    "includeDir ${simp_snmpd::user_trapd_dir}"
  ]

  if $simp_snmpd::manage_client {
    include 'simp_snmpd::install::client'
  }
  else {
    # For some reason the snmp module only creates this directory if the
    # client is included.
    file { '/etc/snmp':
      ensure => directory,
      owner  => 'root',
      group  => 'root',
      mode   => '0750'
    }
  }

  $_snmp_config = [
    "includeFile ${simp_snmpd::snmp_conf_file}"
  ]

  $_autoupgrade = $simp_snmpd::package_ensure ? {
    'latest' => true,
    default  => false
  }

  # build the usm views, access lists, and groups from the hashes in hiera.
  $_viewlist   = simp_snmpd::viewlist($simp_snmpd::view_hash)
  $_grouplist  = simp_snmpd::grouplist($simp_snmpd::group_hash,$simp_snmpd::defsecuritymodel)
  $_accesslist = simp_snmpd::accesslist($simp_snmpd::access_hash,$simp_snmpd::defsecuritymodel,$simp_snmpd::defsecuritylevel)

  # create the users
  class { 'simp_snmpd::v3::users' :
      daemon => 'snmpd'
  }

  # TODO: determine snmpd_options Logging?
  class { 'snmp':
    agentaddress             => $simp_snmpd::agentaddress,
    ensure                   => $simp_snmpd::ensure,
    autoupgrade              => $_autoupgrade,
    service_ensure           => $simp_snmpd::snmpd_service_ensure,
    service_enable           => $simp_snmpd::snmpd_service_startatboot,
    service_config_dir_owner => 'root',
    service_config_dir_group => 'root',
    service_config_perms     => '0750',
    snmpd_config             => $_snmpd_config,
    snmptrapd_config         => $_snmptrapd_config,
    trap_service_ensure      => $simp_snmpd::trap_service_ensure,
    trap_service_enable      => $simp_snmpd::trap_service_startatboot,
    do_not_log_tcpwrappers   => $simp_snmpd::do_not_log_tcpwrappers,
    manage_client            => $simp_snmpd::manage_client,
    snmpd_options            => $simp_snmpd::snmpd_options,
    snmp_config              => $_snmp_config,
    contact                  => $simp_snmpd::contact,
    location                 => $simp_snmpd::location,
    sysname                  => $simp_snmpd::sysname,
    services                 => $simp_snmpd::services,
    disable_authorization    => 'no',
    accesses                 => $_accesslist,
    groups                   => $_viewlist,
    views                    => $_grouplist

  }


}
