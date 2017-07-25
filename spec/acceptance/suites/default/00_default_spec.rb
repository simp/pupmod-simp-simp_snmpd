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
# Install the client utilities (since no trap server, I can't test without these)
simp_snmpd::manage_client: true
    EOH
  }

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
end
