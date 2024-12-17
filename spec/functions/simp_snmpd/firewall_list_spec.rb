require 'spec_helper'

describe 'simp_snmpd::firewall_list' do
  context 'With valid params' do
    it 'returns an array' do
      args = [ 'udp:161',
               'tcp:my.server.com',
               'tcp6:961',
               'udp6:[::1]:999',
               'udp6:[::1f::gg]:777',
               'dtlsudp:161',
               '192.168.33.4:666']
      retval = [
        ['udp', 161, 'ipv4'],
        ['tcp', 161, 'ipv4'],
        ['tcp', 961, 'ipv6'],
        ['udp', 777, 'ipv6'],
        ['udp', 161, 'auto'],
        ['udp', 666, 'ipv4'],
      ]
      is_expected.to run.with_params(args).and_return(retval)
    end
  end
end
