# Returns the version of the snmpd daemon
# installed by net-snmp rpm
#
# @author SIMP Team
#
Facter.add('net_snmp_version') do
  snmpd_command = Facter::Core::Execution.which('snmpd')

  confine do
    not snmpd_command.nil?
  end

  setcode do
    version = 'UNKNOWN'

    # There is no explicit version or help flag for sshd.  Pass
    # a garbage '-v' flag, and grab the output.
    snmpd_out = Facter::Core::Execution.execute(%(#{snmpd_command} -v 2>&1))

    # Case insensitive match to openssh followed by any characters (or no characters),
    # proceeded by digits(any number) and decimals.  Return the digits and decimals.
    version = snmpd_out.match(/NET-SNMP\D*((\d+|\.)+)/i)[1].strip

    version
  end
end

