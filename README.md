[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html) [![Build Status](https://travis-ci.org/simp/pupmod-simp-simp_snmp.svg)](https://travis-ci.org/simp/pupmod-simp-simp_snmp) [![SIMP compatibility](https://img.shields.io/badge/SIMP%20compatibility-6.X-orange.svg)](https://img.shields.io/badge/SIMP%20compatibility-6.X-orange.svg)

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

This module is a component of the
[System Integrity Management Platform](https://github.com/NationalSecurityAgency/SIMP),
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

Set the following in hieradata to configure `snmpd` to:

* Listen on UDP port 161, on the local interface with the ipaddress associated
  with the hostname.  For more information, see the LISTENING ADDRESS section
  of the `snmpd` man page.

* Allow a read-only and a read-write user, `snmp_ro` and `snmp_rw`
  respectively, to access `snmpd`, based on the User Security Model (USM). See
  more information in the Access section, below.

NOTE: The SIMP configuration files are included under `/etc/snmp/simp_snmpd.d`.
If you wish to add configuration files to the SIMP setup, you can add them to
`/etc/snmp/user_snmpd.d` directory.

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
   agentaddress => ["udp:${facts['fqdn']}:161,udp:localhost:161]
}
```

### Access

`simp_snmpd` configures access using the USM module and VACM.  By default, it
will create two users:

* `snmp_ro`:  A user with readonly access to the system information only
* `snmp_rw`:  A user with read/write access to all of SNMP variables

  - Both users and access are configurable via hiera.  See the user guide for
    more information.
  - User passwords are automatically generated using passgen.  They can be
    accessed via passgen using `passgen("snmp_auth_${username}")`
  - The passwords for the users are configured when SNMP is configured the
    first time.  If you need to change them, you will need to use the `snmpsum`
    command, or remove the files in `/var/lib/net-snmp` and run puppet again to
    regenerate them.

### Logging

`simp_snmpd` is configured to send logs to the system daemon.  If `simp_options`
syslog and logrotate are enabled, it will configure rsyslog rules to send
logging to `/var/log/snmpd.log`.

### Firewall

If `simp_options` firewall is enabled, it will parse the
`simp_snmpd::agentaddress` list and configure iptables rules to open those
ports to the trusted nets.  If you want only the snmp manager to be able to
access the system, set `simp_snmpd::trusted_nets` to include only the manager
systems.

### SNMP System Information

`simp_snmpd` configures some basic system information: contact, location,
system name, and services, in the snmpd configuration directory.  You will
probably want to set these.  You can do so via hiera, instantiation, or create
your own configuration file in the user directory.

NOTE: net-snmp does not allow write access to configuration files via a client.
If you want to set information via a client, set `simp_snmpd::system_info` to
false.

### SNMP Client

By default, the snmpd utilities (snmpget, snmpset, etc.) are not included.  To
include them, set `simp_snmp::manage_client` to true.

## Reference

More information is included in the SIMP User Guide under SIMP HOWTO Guides:
Setup SNMP. It includes information on copying additional MIBS and modules to
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

Please read our [Contribution Guide](http://simp-doc.readthedocs.io/en/stable/contributors_guide/index.html).

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
