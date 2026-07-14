require 'spec_helper_acceptance'

test_name 'SIMP SNMPD Profile'

describe 'simp_snmpd class' do
  let(:manifest) do
    <<~EOM
      # Allow ssh incase you need to troubleshoot
      iptables::listen::tcp_stateful { 'allow_sshd':
        order => 8,
        trusted_nets => ['ALL'],
        dports => 22,
      }

      include 'simp_snmpd'
    EOM
  end

  let(:snmphieradata) do
    <<~EOH
      ---
      simp_options::firewall: true
      simp_options::syslog: true
      simp_options::logrotate: true
      simp_options::trusted_nets: ['ALL']
      simp_snmpd::v3_users_hash:
        snmp_ro:
          authpass: 'KeepItSecret'
          privpass: 'KeepItSafe'
        snmp_rw:
          authpass: 'KeepItSecret'
          privpass: 'KeepItSafe'
      # Listen on all interfaces
      simp_snmpd::agentaddress:
      - udp:161
      simp_snmpd::manage_client: true
    EOH
  end
  let(:snmphieradata2) do
    <<~EOH2
      ---
      simp_options::firewall: true
      simp_options::syslog: true
      simp_options::logrotate: true
      simp_options::trusted_nets: ['ALL']
      simp_snmpd::v3_users_hash:
        snmp_ro:
        bar:
          authpass: 'KeepItSecret'
          privpass: 'KeepItSafe'
        foo:
          authpass: 'KeepItSecret'
          privpass: 'KeepItSafe'
      simp_snmpd::group_hash:
        foo_group:
          secname:
            - foo
        bar_group:
          secname:
            - bar
        readonly_group:
      simp_snmpd::access_hash:
        bar:
          view:
            read: iso1
            write: iso1
          level: priv
          groups:
            - bar_group
        foo:
          view:
            read: newsystemview
          level: auth
          groups:
            - foo_group
        systemwrite:
      simp_snmpd::view_hash:
        systemview:
        newsystemview:
          included:
            - '.1.3.6.1.2.1.1'
            - '.1.3.6.1.2.1.25'
      simp_snmpd::system_info: false
      # Listen on all interfaces (0.0.0.0) for both UDP and TCP so the
      # 'check remote' tests can reach the daemon from the other host.
      #
      # The previous value bound to the node's FQDN. On the Vagrant boxes the
      # FQDN resolves to the 127.0.1.1 loopback alias (the box ships a
      # '127.0.1.1 <fqdn> <hostname>' line in /etc/hosts that precedes Beaker's
      # routable entry), so snmpd only listened on loopback and remote queries
      # got 'Connection refused'. A bare 'udp:161'/'tcp:161' binds to 0.0.0.0.
      # Note: do NOT also list 'udp:127.0.0.1:161' here -- it overlaps the
      # wildcard bind and snmpd fails to start with EADDRINUSE.
      simp_snmpd::agentaddress:
      - udp:161
      - tcp:161
      simp_snmpd::manage_client: true
    EOH2
  end

  # Exercise noop from a clean (uninstalled) state: on a fresh node the Sicura
  # console previews the module with `puppet apply --noop`, which must not error
  # even though nothing simp_snmpd manages exists yet. Real idempotence is covered
  # by the applies below. A post-convergence noop check is deliberately omitted:
  # `puppet apply --noop --detailed-exitcodes` always exits 0, so it could never
  # fail and would test nothing.
  context 'in noop mode from a clean state' do
    before(:context) do
      on(hosts, 'puppet resource package net-snmp ensure=absent')
    end

    it 'applies without errors in noop mode' do
      apply_manifest_on(hosts, manifest, catch_failures: true, noop: true)
    end
  end

  context 'with default setting on snmpd agent and client installed' do
    hosts.each do |node|
      it 'sets the hiera data' do
        set_hieradata_on(node, snmphieradata, 'default')
      end

      it 'works with no errors' do
        # apply twice becausel of rsyslog changes
        apply_manifest_on(node, manifest, catch_failures: true)
        apply_manifest_on(node, manifest, catch_failures: true)
      end

      it 'is idempotent' do
        apply_manifest_on(node, manifest, catch_changes: true)
      end

      it 'returns snmp data for users' do
        result = on(node, '/usr/bin/snmpwalk -u snmp_ro -X KeepItSafe -A KeepItSecret localhost sysLocation.0')
        expect(result.stdout).to include('SNMPv2-MIB::sysLocation.0 = STRING: Unknown')
        result = on(node, '/usr/bin/snmpwalk -u snmp_rw -X KeepItSafe -A KeepItSecret localhost .1')
        expect(result.stdout).to include('SNMPv2-MIB::sysLocation.0 = STRING: Unknown')
      end
      it 'does not work for undefined users' do
        result = on(node, '/usr/bin/snmpwalk -u snmp_rx -X KeepItSafe -A KeepItSecret localhost 0', { acceptable_exit_codes: [0, 1] })
        expect(result.exit_code).not_to eq(0)
        expect(result.stderr).to include('Unknown user name')
      end
    end
  end
  context 'with snmpd hiera hash updates' do
    hosts.each do |node|
      it 'removes SNMPv3 users' do
        # `service` is not available on EL9/EL10; use the portable Puppet
        # provider so the daemon is stopped on Vagrant and Docker alike.
        on(node, 'puppet resource service snmpd ensure=stopped')
        on(node, 'rm -rf /var/lib/net-snmp')
      end
    end
    hosts.each do |node|
      it 'sets the hiera data' do
        set_hieradata_on(node, snmphieradata2, 'default')
      end

      it 'runs with no errors' do
        apply_manifest_on(node, manifest, catch_failures: true)
      end
      #      puppet-snmp now includes location in snmpd.conf and you can't get rid
      #      of it.  This makes the value unwritable and this test fails. If we want to test
      #      writing we would have to write our writable MIB.
      #      it 'should create bar user and give it write access' do
      #        result = on(node, '/usr/bin/snmpset -u bar -X KeepItSafe -A KeepItSecret localhost sysLocation.0 s "Over the Rainbow"')
      #        result = on(node, '/usr/bin/snmpwalk -u bar -X KeepItSafe -A KeepItSecret localhost sysLocation.0')
      #        expect(result.stdout).to include("SNMPv2-MIB::sysLocation.0 = STRING: Over the Rainbow")
      #      end
      it 'creates user foo and add give it read access with auth only' do
        result = on(node, '/usr/bin/snmpwalk -u foo -l authNoPriv -A KeepItSecret localhost sysLocation.0')
        expect(result.stdout).to include('SNMPv2-MIB::sysLocation.0 = STRING: Unknown')
      end
      it 'does not create  snmp_ro user' do
        result = on(node, '/usr/bin/snmpwalk -u snmp_ro -X KeepItSafe -A KeepItSecret localhost sysLocation.0', accept_all_exit_codes: true)
        expect(result.stderr).to include('Unknown user name')
      end
    end
  end

  context 'check remote' do
    hosts.each do |client|
      hosts.each do |remote|
        next if client == remote
        it "#{client}, should be able to query the remote server, #{remote}, over tcp" do
          result = on(client, "/usr/bin/snmpwalk -u foo -X KeepItSafe -A KeepItSecret tcp:#{remote}:161 sysLocation.0", accept_all_exit_codes: true)
          expect(result.stdout).to include('SNMPv2-MIB::sysLocation.0 = STRING: Unknown')
        end
        it "#{client}, should be able to query the remote server, #{remote}, over udp" do
          result = on(client, "/usr/bin/snmpwalk -u foo -X KeepItSafe -A KeepItSecret udp:#{remote}:161 sysLocation.0", accept_all_exit_codes: true)
          expect(result.stdout).to include('SNMPv2-MIB::sysLocation.0 = STRING: Unknown')
        end
      end
    end
  end
end
