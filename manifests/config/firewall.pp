# simp_snmpd::config::firewall
#
# @summary This class is meant to be called from simp_snmp.
# It ensures that firewall rules are defined. For anything in the listenagent
# array, it will determine if ports on the firewall need to be opened.
# It ignores any entries for ipx or pvc at this time. IPTABLES calls will have
# to be set up manually if these transport services are being used.
#
class simp_snmpd::config::firewall {
  assert_private()

  $flist = simp_snmpd::firewalllist($simp_snmpd::agentaddress)
  $flist.each |Array $part| {
    case $part[0] {
      'udp': {
        iptables::listen::udp { "snmp-udp-${part[1]}-${part[2]}":
          trusted_nets => $simp_snmpd::trusted_nets,
          apply_to     => $part[2],
          dports       => $part[1]
        }
      }
      'tcp': {
        iptables::listen::tcp_stateful { "snmp-tcp-${part[1]}-${part[2]}":
          trusted_nets => $simp_snmpd::trusted_nets,
          apply_to     => $part[2],
          dports       => $part[1]
        }
      }
      default: {}
    }
  }
}
