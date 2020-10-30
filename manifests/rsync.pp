# simp_snmpd::rsync
#
# @summary Set up MIBs in rsync.
#
class simp_snmpd::rsync{

  include 'rsync'
  $_downcase_os_name = downcase($facts['os']['name'])


  if $simp_snmpd::rsync_dlmod {

    $_group = pick($simp_snmpd::snmpd_gid, 'root')
    $_owner = pick($simp_snmpd::snmpd_uid, 'root')

    file { $simp_snmpd::rsync_dlmod_dir :
      ensure => directory,
      owner  => $_owner,
      group  => $_group,
      mode   => '0750',
      before => Rsync['snmp_dlmod'],
    }

    rsync { 'snmp_dlmod':
      user         => "snmp_${::environment}_${_downcase_os_name}",
      password     => simplib::passgen("snmp_${::environment}_${_downcase_os_name}"),
      source       => "${simp_snmpd::rsync_source}/dlmod",
      target       => $simp_snmpd::rsync_dlmod_dir,
      server       => $simp_snmpd::rsync_server,
      timeout      => $simp_snmpd::rsync_timeout,
      delete       => true,
      preserve_acl => false,
      notify       => Service['snmpd']
    }

    if $simp_snmpd::dlmods {
      $_dlmods = $simp_snmpd::dlmods.map |$dlname| { "dlmod ${dlname} ${simp_snmpd::rsync_dlmod_dir}/dlmod/${dlname}.so"}
      file { "${simp_snmpd::simp_snmpd_dir}/dlmod.conf":
        owner  => $_owner,
        group  => $_group,
        mode    => '0750',
        content => $_dlmods,
        notify  => Service['snmpd']
      }
    }
  }

  # Set up MIBs in rsync
  if $simp_snmpd::rsync_mibs {

    file { $simp_snmpd::rsync_mibs_dir :
      ensure => directory,
      owner  => $_owner,
      group  => $_group,
      mode   => '0750',
      before => Rsync['snmpd_mibs'],
    }

    rsync { 'snmpd_mibs':
      user     => "snmp_${::environment}_${_downcase_os_name}",
      password => simplib::passgen("snmp_${::environment}_${_downcase_os_name}"),
      server   => $simp_snmpd::rsync_server,
      timeout  => $simp_snmpd::rsync_timeout,
      source   => "${simp_snmpd::rsync_source}/mibs",
      target   => $simp_snmpd::rsync_mibs_dir,
      notify   => Service['snmpd'],
    }

  }

}
