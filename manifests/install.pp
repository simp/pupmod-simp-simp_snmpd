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

  $_service_config_dir_group = $simp_snmpd::snmpd_gid ? {
    undef   => 'root',
    default => 'snmp'
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
  if $simp_snmpd::include_userdir {
    $user_dir_ensure = 'directory'
    $_snmpd_config  = [
      "includeDir ${simp_snmpd::simp_snmpd_dir}",
      "includeDir ${simp_snmpd::user_snmpd_dir}"
    ]
  }
  else {
    $user_dir_ensure = 'absent'
    $_snmpd_config  = [
      "includeDir ${simp_snmpd::simp_snmpd_dir}"
    ]
  }

  file { $simp_snmpd::simp_snmpd_dir:
    ensure => 'directory',
    owner  => 'root',
    group  => pick($simp_snmpd::snmpd_gid,'root'),
    mode   => '0750',
    require => File[$simp_snmpd::snmp_basedir]
  }
  file { $simp_snmpd::user_snmpd_dir:
    ensure => $user_dir_ensure,
    owner  => 'root',
    group  => pick($simp_snmpd::snmpd_gid,'root'),
    mode   => '0750',
    require => File[$simp_snmpd::snmp_basedir]
  }

  if $simp_snmpd::manage_client {
    #set defaults for client in snmp.conf
    $_snmp_config = [
      "defVersion  ${simp_snmpd::version}",
      "defSecurityModel ${simp_snmpd::defsecuritymodel}",
      "defSecurityLevel ${simp_snmpd::defsecuritylevel}",
      "defAuthType ${simp_snmpd::defauthtype}",
      "defPrivType ${simp_snmpd::defprivtype}",
      "mibdirs /usr/share/snmp/mibs:${simp_snmpd::rsync_mibs_dir}/mibs",
    ]
  }
  else {
    # For some reason the snmp module only creates this directory if the
    # client is included.
    $_snmp_config = []
    file { $simp_snmpd::snmp_basedir:
      ensure => directory,
      owner  => 'root',
      group  => pick($simp_snmpd::snmpd_gid,'root'),
      mode   => '0750'
    }
  }

  $_autoupgrade = $simp_snmpd::package_ensure ? {
    'latest' => true,
    default  => false
  }
  # If the trap daemon is set to  be running then create the trap config dir
  # and add an include directive to the trap config file.
  if $simp_snmpd::trap_service_ensure != 'stopped' {
    $_snmptrapd_config =  [ "includeDir ${simp_snmpd::user_trapd_dir}" ]
    $_user_trapdir_ensure = 'directory'
  } else {
    $_snmptrapd_config =  []
    $_user_trapdir_ensure = 'absent'
  }
  file { $simp_snmpd::user_trapd_dir:
    ensure => $_user_trapdir_ensure,
    owner  => 'root',
    group  => pick($simp_snmpd::snmpd_gid,'root'),
    mode   => '0750'
  }

  # build the usm views, access lists, and groups from the hashes in hiera.
  $_viewlist   = simp_snmpd::viewlist($simp_snmpd::view_hash)
  $_grouplist  = simp_snmpd::grouplist($simp_snmpd::group_hash,$simp_snmpd::defsecuritymodel)
  $_accesslist = simp_snmpd::accesslist($simp_snmpd::access_hash,$simp_snmpd::defsecuritymodel,$simp_snmpd::defsecuritylevel)

  # create the users
  class { 'simp_snmpd::install::users' :
      daemon => 'snmpd'
  }

  class { 'snmp':
    agentaddress             => $simp_snmpd::agentaddress,
    ensure                   => $simp_snmpd::ensure,
    autoupgrade              => $_autoupgrade,
    service_ensure           => $simp_snmpd::snmpd_service_ensure,
    service_enable           => $simp_snmpd::snmpd_service_startatboot,
    service_config_dir_owner => 'root',
    service_config_dir_group => $_service_config_dir_group,
    service_config_perms     => '0750',
    snmpd_options            => $simp_snmpd::snmpd_options,
    snmpd_config             => $_snmpd_config,
    snmptrapd_config         => $_snmptrapd_config,
    trap_service_ensure      => $simp_snmpd::trap_service_ensure,
    trap_service_enable      => $simp_snmpd::trap_service_startatboot,
    snmptrapd_options        => $simp_snmpd::snmptrapd_options,
    do_not_log_tcpwrappers   => $simp_snmpd::do_not_log_tcpwrappers,
    manage_client            => $simp_snmpd::manage_client,
    snmp_config              => $_snmp_config,
    contact                  => $simp_snmpd::contact,
    location                 => $simp_snmpd::location,
    sysname                  => $simp_snmpd::sysname,
    services                 => $simp_snmpd::services,
    disable_authorization    => 'no',
    com2sec                  => [],
    com2sec6                 => [],
    accesses                 => $_accesslist,
    views                    => $_viewlist,
    groups                   => $_grouplist

  }

}
