# Let user set up rsync of  mibs.  It should be
# optional
#
class simp_snmpd::rsync{

  include rsync
  $_downcase_os_name = downcase($facts['os']['name'])


  if $simp_snmpd::rsync_dlmod {

    file { $simp_snmpd::rsync_dlmod_dir :
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0750',
      before => Rsync['snmp_dlmod'],
    }

    rsync { 'snmp_dlmod':
      user         => "snmp_${::environment}_${_downcase_os_name}",
      password     => passgen("snmp_${::environment}_${_downcase_os_name}"),
      source       => "${simp_snmpd::rsync_source}/dlmod",
      target       => $simp_snmpd::rsync_dlmod_dir,
      server       => $simp_snmpd::rsync_server,
      timeout      => $simp_snmpd::rsync_timeout,
      delete       => true,
      preserve_acl => false,
      notify       => [
        Service['snmpd'],
        Exec['set_snmp_perms']
      ]
    }
    # Then for each module you need to add it to a config file in simp snmpd direcory and restart snmpd service
    # dlmod NAME PATH
    # will load the shared object module from the file PATH (an absolute filename), and call the initialisation routine init_NAME.
    # Note:  If the specified PATH is not a fully qualified filename, it will be interpreted relative to /usr/lib(64)/snmp/dlmod, and .so will be appended to the filename.
  }

  #sset up rsync of mibs
  if $simp_snmpd::rsync_mibs {

    file { $simp_snmpd::rsync_mibs_dir :
      ensure => directory,
      owner  => root,
      group  => root,
      mode   => '0750',
      before => Rsync['snmp_mibs'],
    }

    rsync { 'snmpd_mibs':
      user     => "snmp_${::environment}_${_downcase_os_name}",
      password => passgen("snmp_${::environment}_${_downcase_os_name}"),
      server   => $simp_snmpd::rsync_server,
      timeout  => $simp_snmpd::rsync_timeout,
      source   => "${simp_snmpd::rsync_source}/mibs",
      target   => $simp_snmpd::rsync_mib_dir,
      notify   => [
        Service['snmpd'],
        Exec['set_snmp_perms']
      ]
    }

  }

}

