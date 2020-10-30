[![License](https://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html)
[![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/73/badge)](https://bestpractices.coreinfrastructure.org/projects/73)
[![Puppet Forge](https://img.shields.io/puppetforge/v/simp/simp_snmpd.svg)](https://forge.puppetlabs.com/simp/simp_snmpd)
[![Puppet Forge Downloads](https://img.shields.io/puppetforge/dt/simp/simp_snmpd.svg)](https://forge.puppetlabs.com/simp/simp_snmpd)
[![Build Status](https://travis-ci.org/simp/pupmod-simp-simp_snmpd.svg)](https://travis-ci.org/simp/pupmod-simp-simp_snmpd)

#### Table of Contents

1. [Description](#description)
2. [Setup - The basics of getting started with simp_snmp](#setup)
    * [What simp_snmp affects](#what-simp_snmp-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with simp_snmp](#beginning-with-simp_snmp)
3. [Usage - Configuration options and additional functionality](#usage)
4. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)
    * [Acceptance Tests - Beaker env variables](#acceptance-tests)

## Description

This module is a [SIMP](https://simp-project.com) Puppet profile for setting up
SNMP v3, and USM configuration.

### This is a SIMP module

This module is a component of the [System Integrity Management Platform](https://simp-project.com),
a compliance-management framework built on Puppet.

If you find any issues, they should be submitted to our
[bug tracker](https://simp-project.atlassian.net/).


This module is designed for use within a SIMP ecosystem, but it can be used
independently.

* When included within a SIMP ecosystem, security compliance settings will be
  managed from the Puppet server.

* If used independently, all SIMP-managed security subsystems are disabled by
  default and must be explicitly opted into by administrators.  Please review
  the parameters in
  [`simp/simp_options`](https://github.com/simp/pupmod-simp-simp_options) for
  details.

This module is a simp profile module and configures snmp using version 3
with usm authentication.  To configure snmp in a different way use
puppet-snmpd directly.

## Setup

### What simp_snmp Affects

This profile wraps around the
[puppet-snmp module](https://github.com/simp/puppet-snmp).  It is designed to:

* Install the `net-snmpd` package
* Configure and manage the `snmpd` service
* Optionally install the `net-snmp-utils` package and manage clients

NOTE: This module does not configure `snmptrapd`.  This module will,
default, ensure `snmptrapd` is stopped and disabled. If you decide to enable
`snmptrapd`, you must configure it manually.

### Beginning With simp_snmp

Install the `puppet-snmp` and `pupmod-simp-simp_snmpd` modules. The `net-snmp`
and `net-snmp-utils` packages and their dependencies must be available through
the package manager.

## Usage


Simp_snmpd configures the snmpd daemon to listen only on the local interface by default.
Set the following in hieradata to configure `snmpd` to Listen on UDP port 161
on the local interface and the the interface with the ipaddress associated
with the hostname.  For more information, see the LISTENING ADDRESS section
  of the `snmpd` man page.


``` yaml
---
simp_snmpd::agentaddress:
- udp:localhost:161
- udp:%{facts.fqdn}:161

classes:
  - simp_snmpd
```

Or, via instantiation:

``` ruby
class { simp_snmpd:
   agentaddress => ["udp:${facts['fqdn']}:161",'udp:localhost:161']
}
```

See the "Access" section for details on how the access is configured.

There are a few snmp options that can be configured directly from this
module via hiera.  If you wish to add configuration files to the SIMP setup set
`simp_snmpd::include_userdir` to true, and add and configuration files
to the directory defined by `simp_snmpd::user_snmpd_dir`,
by default `/etc/snmp/snmpd.d`.

### Access

`simp_snmpd` configures access using the User-based Security Module (USM)
and View-based Access Control Model (VACM).  By default, it
will create two users:

* `snmp_ro`:  A user with readonly access to the system information only
* `snmp_rw`:  A user with read/write access to all SNMP variables

  - Both users and access are configurable via hiera.  See the SIMP user
    guide, How To Configure SNMPD for more information.
  - User passwords are automatically generated using SIMP's passgen from the
    simplib module.  The SIMP user guide General Administration section gives
    information on where these passwords are stored.
  - The passwords for the users are configured when SNMP is configured the
    first time.  If you need to change them, you will need to use the `snmpusm`
    command, or remove  `/var/lib/net-snmp` and run `puppet` again to
    regenerate all of them.

### Logging

`simp_snmpd` is configured to send logs to the system daemon.  If `simp_options`
syslog and logrotate are enabled, it will configure rsyslog rules to send
logging to `/var/log/snmpd.log`.

This is configured via the `simp_snmpd::snmpd_options` setting.  These are
the options sent to the snmpd daemon on start up.  By default it is logging
to facility 6 which will be forwarded to the server if log forwarding is enabled.

For more information on these options see the man page for snmpcmd,
the Logging section.  `Snmpcmd` and its man pages are installed with the 
`net-snmp-utils` package.

### Firewall

If `simp_options` firewall is enabled, it will parse the
`simp_snmpd::agentaddress` list and configure iptables rules to open those
ports to the trusted nets.  If you want only the SNMP manager to be able to
access the system, set `simp_snmpd::trusted_nets` to include only the manager
systems addresses.

### SNMP System Information

`simp_snmpd` configures some basic system information: contact, location
system name, and services, in the snmpd configuration directory.  These settings
can be changed via hiera, instantiation, by creating a configuration file
in the user directory.

NOTE: If the system variables are set in a configuration file then `net-snmp`
marks them as not writable and will not allow them to be changed via `snmpset`
or other client utilities.
To be able to set information via a client, set `simp_snmpd::system_info` to
false and the defaults will not be set in the configuration file.

### SNMP Client

By default, the snmpd utilities (`snmpget`, `snmpset`, etc.) are not included.  To
include them, set `simp_snmp::manage_client` to true.

## Reference

More information is included in the SIMP User Guide under SIMP HOWTO Guides:
Configure SNMP. It includes information on copying additional MIBS and modules to
the system.

## Limitations

This is a SIMP Profile. It will not expose **all** options of the underlying
modules, only the ones that are conducive to a supported SIMP infrastructure.
If you need to do things that this module does not cover, you may need to
create your own profile or inherit this profile and extend it to meet your
needs.

SIMP Puppet modules are generally intended for use on Red Hat Enterprise Linux
and compatible distributions, such as CentOS. Please see the
[`metadata.json` file](./metadata.json) for the most up-to-date list of
supported operating systems, Puppet versions, and module dependencies.

## Development

Please read our [Contribution Guide](https://simp.readthedocs.io/en/stable/contributors_guide/index.html).

### Acceptance tests

This module includes [Beaker](https://github.com/puppetlabs/beaker) acceptance
tests using the SIMP [Beaker Helpers](https://github.com/simp/rubygem-simp-beaker-helpers).
By default the tests use [Vagrant](https://www.vagrantup.com/) with
[VirtualBox](https://www.virtualbox.org) as a back-end; Vagrant and VirtualBox
must both be installed to run these tests without modification. To execute the
tests run the following:

```shell
bundle install
bundle exec rake beaker:suites
```
Please refer to the [SIMP Beaker Helpers documentation](https://github.com/simp/rubygem-simp-beaker-helpers/blob/master/README.md)
for more information.
