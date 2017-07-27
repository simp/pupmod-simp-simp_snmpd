# == Class simp_snmpd::config::firewall
#
# This class is meant to be called from simp_snmp.
# It ensures that firewall rules are defined.
# for anything in the listenagent array
class simp_snmpd::config::firewall {
  assert_private()

  if $simp_snmpd::agentaddress {
    $simp_snmpd::agentaddress.each | Array $address | {
      case $address[0] {
        /(udp|udp6)/: {
          iptables::listen::udp { "snmp-udp-${address}":
            trusted_nets => $simp_snmpd::trusted_nets,
            dports       => [ $address[2] ]
          }
        }
        #case $protocal
        #'udp|udp6':{}
        #'tcp|tcp6':{}
        default:  {$proto = 'tcp'}
      }
    }
  }
}
