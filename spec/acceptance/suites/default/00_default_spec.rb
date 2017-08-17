require 'spec_helper_acceptance'

test_name 'SIMP SNMPD Profile'

describe 'simp_snmpd class' do
  let(:manifest) {
    <<-EOM
      include 'simp_snmpd'
    EOM
  }

  let(:snmphieradata) { <<-EOH
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
# Install the client utilities (since no trap server, I can't test without these)
simp_snmpd::manage_client: true
    EOH
  }
  let(:snmphieradata2) { <<-EOD
---
simp_options::firewall: true
simp_options::syslog: true
simp_options::logrotate: true
simp_options::trusted_nets: ['ALL']
simp_snmpd::v3_users_hash:
  snmp_ro:
  foo:
    authpass: 'KeepItSecret'
    privpass: 'KeepItSafe'
  bar:
    authpass: 'KeepItSecret'
    privpass: 'KeepItSafe'
simp_snmpd::groups_hash:
  readonly_group:
    secname:
      - foo
      - snmp_ro
  bar_group:
    secname:
      - bar
simp_snmpd::access_hash:
  new:
    view:
      read: iso1
      write: iso1
    level: auth
    groups:
      - bar_group
simp_snmpd::system_info: false
simp_snmpd::agentaddress:
 - udp:localhost:161
 - tcp:%{facts.fqdn}:161
# Install the client utilities (since no trap server, I can't test without these)
simp_snmpd::manage_client: true
    EOD
  }

  servers = hosts_with_role( hosts, 'server' )
  clients = hosts_with_role( hosts, 'client' )
  el7 = hosts_with_role(hosts, 'el7')
  el6 = hosts_with_role(hosts, 'el6')

  context 'with default setting on snmpd agent and client installed' do
    hosts.each do |node|

      it 'should set the hiera data' do
        set_hieradata_on(node, snmphieradata, 'default')
      end

      it 'should work with no errors' do
      # Using puppet_apply as a helper
        apply_manifest_on(node, manifest, :catch_failures => true)
      end

      it 'should be idempotent' do
        apply_manifest_on(node, manifest, :catch_failures => true)
      end

      describe package('net-snmp') do
        it { is_expected.to be_installed }
      end

      describe service('snmpd') do
        it { is_expected.to be_enabled }
        it { is_expected.to be_running }
      end
      it 'should return snmp data for users' do
        result = on(node, '/usr/bin/snmpwalk -u snmp_ro -X KeepItSafe -A KeepItSecret localhost sysLocation.0')
        expect(result.stdout).to include("SNMPv2-MIB::sysLocation.0 = STRING: Unknown")
        result = on(node, '/usr/bin/snmpwalk -u snmp_rw -X KeepItSafe -A KeepItSecret localhost sysLocation.0')
        expect(result.stdout).to include("SNMPv2-MIB::sysLocation.0 = STRING: Unknown")
      end
      it 'should not work for undefined users' do
        result = on(node, '/usr/bin/snmpwalk -u snmp_rx -X KeepItSafe -A KeepItSecret localhost sysLocation.0', { :acceptable_exit_codes => [0,1] })
        expect(result.exit_code).to_not eq(0)
        expect(result.stderr).to include("Unknown user name (Sub-id not found: (top)")
      end
    end
  end
  context 'with snmp installed and firewalls on' do
    it 'the firewalls should be open so a remote query can be done'  do
      servers.each do |node|
        clients.each do |client|
          result = on(node,"/usr/bin/snmpwalk -u snmp_ro -X KeepItSafe -A KeepItSecret #{client} sysLocation.0")
          expect(result.stdout).to include("SNMPv2-MIB::sysLocation.0 = STRING: Unknown")
        end
      end
    end
  end
  context 'remove the usm users to  so we can recreate' do
    hosts.each do |node|
      it 'should remove old data' do
        on(node,'rm -rf /var/lib/net-snmp /etc/snmp')
        os_release = fact_on(node, 'operatingsystemmajrelease')
        if os_release == '6'
          on(node,'service snmpd stop',  :accept_all_exit_codes => true )
        else
          on(node,'/bin/systemctl stop snmpd', :accept_all_exit_codes => true)
        end
      end
      it 'should set the hiera data 2' do
        set_hieradata_on(node, snmphieradata2, 'default')
      end

      it 'should rerun with no errors' do
       # Using puppet_apply as a helper
         apply_manifest_on(node, manifest, :catch_failures => true)
      end
      it 'should not create  snmp_ro user' do
        result = on(node, '/usr/bin/snmpwalk -u snmp_ro -X KeepItSafe -A KeepItSecret localhost sysLocation.0, :accept_all_exit_codes => true')
        expect(result.stdout).to include("Unknown user name")
      end
      it 'should create bar user and give it write access' do
         result = on(node, '/usr/bin/snmpset -u foo -X KeepItSafe -A KeepItSecret localhost sysLocation.0 s "Over the Rainbow"')
         result = on(node, '/usr/bin/snmpwalk -u foo -X KeepItSafe -A KeepItSecret localhost sysLocation.0')
         expect(result.stdout).to include("SNMPv2-MIB::sysLocation.0 = STRING: Over the Rainbow")
      end
      it 'should create user foo and add give it read access with auth only' do
        result = on(node, '/usr/bin/snmpwalk -u foo -l authNoPriv -A KeepItSecret localhost sysLocation.0')
        expect(result.stdout).to include("SNMPv2-MIB::sysLocation.0 = STRING: Over the Rainbow")
      end
    end
  end
end
