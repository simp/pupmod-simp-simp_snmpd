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
    agent_array.each do |addr|
      protocol = ''
      specifier = ''
      parts = addr.split(':')
      # Check if there is a protocol specified
      case parts[0]
      when %r{^(?i:(((udp)(((ip)?v)?6)?)|dtlsudp))$}
        protocol = 'udp'
        specifier = parts[0]
        parts.shift
      when %r{^(?i:(((tcp)(((ip)?v)?6)?)|ssh|tsl(tcp)?))$}
        specifier = parts[0]
        protocol = 'tcp'
        parts.shift
      when %r{^(?i:(ipx|(aal5)?pvc|unix))$}
        # do nothing for these
        parts = []
      when %r{^[/].*$}
        parts = []
      else
        protocol = 'udp'
        specifier = 'udp'
      end
      if parts.count == 2
        # there is a host name or IPV4 address in part[0] and a port in part 1
        if ['localhost', '127.0.0.1'].include? parts[0]
          parts = []
        else
          parts.shift
        end
      elsif parts.count > 2
        # we have an ipv6 address.
        all = parts.join.split(']')
        parts = if addr.include?('[::1]')
                  []
                elsif all[1]
                  [ all[1] ]
                else
                  [ '161' ]
                end
        # No "else" because there is either one part and it is taken take care of in the next section
        # or no parts and nothing needs to be done.
      end
      next unless parts.count == 1
      # Check it parts is a port.  If not it is a specifier without
      # a port so we set the default
      x = parts[0].to_i
      port = if (x > 0) && (x < 65_535)
               x
             else
               case specifier
               when %r{^(?i:ssh)$}
                 22
               else
                 161
               end
             end
      # Check if it specifies ipv6 or ipv4 and set the apply value
      # for iptables
      apply = case specifier
              when %r{^(?i:(udp|tcp))$}
                'ipv4'
              when %r{^*6$}
                'ipv6'
              else
                'auto'
              end
      firewall_list.push [ protocol, port, apply ]
    end
    firewall_list.uniq!
    firewall_list
  end
end
