require 'spec_helper'

describe 'simp_snmpd' do

  shared_examples_for "a structured module" do
      it { is_expected.to compile.with_all_deps }
      it { is_expected.to contain_class('simp_snmpd') }
      it { is_expected.to contain_class('simp_snmpd::install').that_comes_before('Class[simp_snmpd::config]') }
      it { is_expected.to contain_class('simp_snmpd::config').that_comes_before('Class[simp_snmpd::access]') }
      it { is_expected.to contain_class('simp_snmpd::access') }
      it { is_expected.to  create_file('/etc/snmp/simp_snmpd.d') }
      it { is_expected.to  create_file('/etc/snmp/simp_snmpd.d/access.conf') }
      it { is_expected.to  create_file('/etc/snmp/snmpd.d') }
      it { is_expected.to create_package('snmpd').with_ensure('present') }
      it { is_expected.to create_service('snmpd').with_ensure('running') }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context "simp_snmp class without any parameters" do
          let(:params) {{ }}
          it_behaves_like "a structured module"
          #install.pp
          it { is_expected.to_not contain_class('simp_snmpd::install::client') }
          it { is_expected.to contain_class('snmp').with({
            :agentaddress             => ['udp:127.0.0.1:161','udp6:[::1]:161'],
            :ensure                   => 'present',
            :autoupgrade              => 'false',
            :service_ensure           => 'running',
            :service_enable           => 'true',
            :service_config_dir_group => 'root',
            :template_snmpd_conf      => 'simp_snmpd/snmpd/snmpd.conf.erb',
            :snmpd_config             => ['includeDir /etc/snmp/simp_snmpd.d','includeDir /etc/snmp/snmpd.d'],
            :trap_service_ensure      => 'stopped',
            :trap_service_enable      => 'false',
            :do_not_log_traps         => 'no',
            :do_not_log_tcpwrappers   => 'no',
            :manage_client            => 'false',
            :snmp_config              => ['includeFile /etc/snmp/simp_snmp.conf']
            })
          }
          # config.pp
          it { is_expected.to_not contain_class('simp_snmpd::config::firewall')}
          it { is_expected.to_not contain_class('simp_snmpd::config::tcpwrappers')}
          it { is_expected.to_not contain_class('simp_snmpd::config::logging')}
          it { is_expected.to_not contain_class('simp_snmpd::rsync')}
          it { is_expected.to contain_class('simp_snmpd::v3::users')}
          it { is_expected.to contain_exec('set_snmp_perms').with_command('/usr/bin/setfacl -R -m g:snmp:r /etc/snmp  ')}
        end
        context "simp_snmp class with rsync on" do
          let(:params) {{
            :rsync_dlmod => true,
            :rsync_mibs  => true,
            :rsync_mibs_dir => '/etc/mibs_here',
            :rsync_dlmod_dir => '/etc/dlmod_there'
          }}
          it { is_expected.to contain_class('simp_snmpd::rsync') }
          it { is_expected.to contain_exec('set_snmp_perms').with_command('/usr/bin/setfacl -R -m g:snmp:r /etc/snmp /etc/dlmod_there /etc/mibs_here')}
          it { is_expected.to contain_file('/etc/mibs_here') }
          it { is_expected.to contain_file('/etc/dlmod_there') }
        end
      end
    end
  end
end
