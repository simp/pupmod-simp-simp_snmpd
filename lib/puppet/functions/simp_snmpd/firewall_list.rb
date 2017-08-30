# function to return a list of protocol and ports to open in
# iptables for snmpd to work.
Puppet::Functions.create_function(:'simp_snmpd::firewall_list') do
  # @param agent_array
  #   The array of agent addresses that the snmpd  will listen on.
  #
  # @return
  #    A list of protocols and ports that must be opened.
  #
  dispatch :createlist do
    param 'Array', :agent_array
  end

  def createlist(agent_array)
    firewall_list = []
    agent_array.each { | addr |
      protocol = ''
      specifier = ''
      parts = addr.split(':')
      # Check if there is a protocol specified
      case parts[0]
      when /^(?i:(((udp)(((ip)?v)?6)?)|dtlsudp))$/
        protocol = 'udp'
        specifier = parts[0]
        parts.shift
      when /^(?i:(((tcp)(((ip)?v)?6)?)|ssh|tsl(tcp)?))$/
        specifier = parts[0]
        protocol = 'tcp'
        parts.shift
      when /^(?i:(ipx|(aal5)?pvc|unix))$/
       # do nothing for these
        parts = []
      when /^[\/].*$/
        parts = []
      else
        protocol = 'udp'
        specifier = 'udp'
      end
      case
      when parts.count == 2
        # there is a host name or IPV4 address in part[0] and a port in part 1
        if ( ['localhost','127.0.0.1'].include? parts[0]) then
          parts = []
        else
          parts.shift
        end
      when parts.count > 2
        # we have an ipv6 address.
        all = parts.join.split(']')
        if addr.match(/\[::1\]/) then
          parts = []
        elsif all[1] then
          parts = [ all[1] ]
        else
          parts = [ '161' ]
        end
        # No "else" because there is either one part and it is taken take care of in the next section
        # or no parts and nothing needs to be done.
      end
      if  parts.count == 1 then
        # Check it parts is a port.  If not it is a specifier without
        # a port so we set the default
        x = parts[0].to_i
        if x > 0 and x < 65535 then
          port = x
        else
          case specifier
          when /^(?i:ssh)$/
            port = 22
          else
            port = 161
          end
        end
        # Check if it specifies ipv6 or ipv4 and set the apply value
        # for iptables
        case specifier
        when /^(?i:(udp|tcp))$/
          apply = 'ipv4'
        when /^*6$/
          apply = 'ipv6'
        else
          apply = 'auto'
        end
        firewall_list.push [ protocol, port, apply ]
      end
    }
    firewall_list.uniq!
    firewall_list
  end
end
