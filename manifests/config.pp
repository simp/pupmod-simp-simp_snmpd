# @summary Configure the SNMPD service
#
class simp_snmpd::config {
  assert_private()

  # Create agent setting in agent.conf
  contain simp_snmpd::config::agent

  if $simp_snmpd::firewall {
    include simp_snmpd::config::firewall
  }

  if $simp_snmpd::tcpwrappers {
    include simp_snmpd::config::tcpwrappers
  }

  if $simp_snmpd::syslog {
    include simp_snmpd::config::logging
  }

}
