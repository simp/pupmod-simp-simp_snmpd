[![License](http://img.shields.io/:license-apache-blue.svg)](http://www.apache.org/licenses/LICENSE-2.0.html) [![Build Status](https://travis-ci.org/simp/pupmod-simp-simp_snmp.svg)](https://travis-ci.org/simp/pupmod-simp-simp_snmp) [![SIMP compatibility](https://img.shields.io/badge/SIMP%20compatibility-6.*-orange.svg)](https://img.shields.io/badge/SIMP%20compatibility-6.*-orange.svg)

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
the snmpd using version 3 USM configuration as supported by the SIMP ecosystem.



### This is a SIMP module

This module is a component of the [System Integrity Management
Platform](https://github.com/NationalSecurityAgency/SIMP), a
compliance-management framework built on Puppet.

If you find any issues, they may be submitted to our [bug
tracker](https://simp-project.atlassian.net/).


This module is optimally designed for use within a larger SIMP ecosystem, but
it can be used independently:

 * When included within the SIMP ecosystem, security compliance settings will
   be managed from the Puppet server.
 * If used independently, all SIMP-managed security subsystems are disabled by
   default and must be explicitly opted into by administrators.  Please review
   the parameters in
   [`simp/simp_options`](https://github.com/simp/pupmod-simp-simp_options) for
   details.

## Setup

### What simp_snmp affects


 * This calls the snmp module to install the net-snmpd package  and,
   if manage_client is enabled, net-snmp-utils package.
 * It uses the snmp module to manage the snmpd service.
 * This module does not configure the snmptrapd.  This module will by
   default tell the snmp module to stop the snmptrapd. If you enable the
   snmptrapd daemon, its configuration files must be configured manually.

### Beginning with simp_snmp

The puppet-snmp and pupmod-simp-simp_snmpd modules should be installed prior to setting this
up.  The net-snmp and net-snmp-utils modules and their dependacies must be available through
the package manager.

## Usage

To set up the snmpd daemon and configure users to access it using authentication and privacy
use the following hieradata:

``` yaml
---
simp_snmpd::agentaddress:
- udp:localhost:161
- udp:%{facts.fqdn}:161

classes:
  - simp_snmpd
```
or an equivalant call

``` ruby
class { simp_snmpd:
   agentaddress => ["udp:${facts['fqdn']}:161,udp:localhost:161]
}
```

This will configure the snmpd to listen on udp port 161 to the local interface and the interface configured
for the ip address of the  hostname.  By default it will only listen on the local interface.
For more information on configuring agentaddress list see the LISTENING ADDRESS section of the
snmpd man page.

NOTE:  The simp configuration files are included under /etc/snmp/simp_snmpd.d.  If you wish to
add configuration files outside of the simp setup you can add them to /etc/snmp/user_snmpd.d.

### Access

Simp_snmpd configures access using the USM module and VACM.  By default it will create
two users whose passwords are automatically generated using passgen.  They
can be accessed by passgen using passgen("snmp_auth_${username}").
* snmp_ro:  A user with readonly access to the system information only.
* snmp_rw:  A user with read/write access to all of snmp variables.

The users and access are configurable via hiera.  See the user guide for more information.

The passwords for the users are configured when snmpd is configured the first time.
If you need to change them you will need to use the snmpusm command  or remove the
files in /var/lib/net-snmp and run puppet again to regenerate them.

### Logging

Simp_snmpd configures logging to send logs to the system daemon.  If the simp_options syslog and logrotate
are enabled it will configure rsyslog rules to send logging to /var/log/snmpd.log.

### Firewall
If simp_options firewall is enabled it will parse the simp_snmpd::agentaddress list and configure
iptables rules to open those ports to the trusted nets.  If you want only the snmp manager to be
able to access the system set simp_snmpd::trusted_nets to be only the manager systems.

### SNMP System Information
Simp_snmpd configures some basic system information, contact, location, system name and services in the snmpd configuration
directory.  You will probably want to set these.  You can do this via hiera, the system call or create your own
configuration file in the user directory.  If they are set in the configuration files, net-snmp does not
allow write access to these via a client.  If you want to set these via a client the disable the system info by
setting simp_snmpd::system_info to false.

### SNMP Client
By default the snmpd utilities, snmpget, snmpset etc are not included.  To include these
set simp_snmp::manage_client to true.

## Reference

More information is included in the SIMP User Guide under SIMP HOWTO Guides: Setup SNMP.
This includes information on copying up additional MIBS and modules to the systems.


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
