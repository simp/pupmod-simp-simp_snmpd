require 'spec_helper'

describe 'simp_snmpd' do
  shared_examples_for 'a structured module' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('simp_snmpd') }
    it { is_expected.to contain_class('simp_snmpd::install').that_comes_before('Class[simp_snmpd::config]') }
    it { is_expected.to contain_class('simp_snmpd::config') }
    it { is_expected.to create_service('snmpd').with_ensure('running') }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'simp_snmp class without any parameters' do
          let(:expected) { File.read('spec/expected/default_access_usm_conf') }
          let(:params) { {} }

          it_behaves_like 'a structured module'
          it { is_expected.not_to contain_class('simp_snmpd::rsync') }
        end
        context 'install manifest with default parameters' do
          it { is_expected.to contain_class('simp_snmpd::install::vacmusers') }
          # install.pp
          it {
            is_expected.to contain_class('snmp').with({
                                                        agentaddress: ['udp:127.0.0.1:161'],
            ensure: 'present',
            autoupgrade: 'false',
            service_ensure: 'running',
            service_enable: 'true',
            service_config_dir_owner: 'root',
            service_config_dir_group: 'root',
            service_config_perms: '0600',
            service_config_dir_perms: '0750',
            snmpd_config: ['includeDir /etc/snmp/simp_snmpd.d'],
            snmptrapd_config: [],
            trap_service_ensure: 'stopped',
            trap_service_enable: 'false',
            do_not_log_tcpwrappers: 'no',
            manage_client: 'false',
            snmp_config: [],
            views: [ 'systemview included .1.3.6.1.2.1.1',
                     'systemview included .1.3.6.1.2.1.25.1.1',
                     'iso1 included .1' ],
            groups: ['readonly_group usm snmp_ro',
                     'readwrite_group usm snmp_rw' ],
            accesses: ['readonly_group "" usm priv exact systemview none none',
                       'readwrite_group "" usm priv exact iso1 systemview none'],

                                                      })
          }
          it { is_expected.not_to contain_class('simp_snmpd::install::snmpduser') }
          it { is_expected.not_to contain_class('simp_snmpd::install::client') }
          it { is_expected.to create_file('/etc/snmp/simp_snmpd.d') }
          it {
            is_expected.to create_file('/etc/snmp/snmpd.d').with({
                                                                   ensure: 'absent'
                                                                 })
          }
          it {
            is_expected.to create_file('/etc/snmp/snmptrapd.d').with({
                                                                       ensure: 'absent'
                                                                     })
          }
        end
        context 'config with default params' do
          it { is_expected.to create_file('/etc/snmp/snmptrapd.d') }
          it { is_expected.to contain_class('simp_snmpd::config::agent') }
          it { is_expected.to create_file('/etc/snmp/simp_snmpd.d/agent.conf') }
          it { is_expected.not_to contain_class('simp_snmpd::config::firewall') }
          it { is_expected.not_to contain_class('simp_snmpd::config::tcpwrappers') }
          it { is_expected.not_to contain_class('simp_snmpd::config::logging') }
        end
        context 'install/users with default parameters' do
          it {
            is_expected.to contain_snmp__snmpv3_user('snmp_ro').with({
                                                                       authtype: 'SHA',
            privtype: 'AES'
                                                                     })
          }
          it {
            is_expected.to contain_snmp__snmpv3_user('snmp_rw').with({
                                                                       authtype: 'SHA',
            privtype: 'AES'
                                                                     })
          }
        end

        context 'simp_snmp class with rsync on' do
          let(:params) do
            {
              rsync_dlmod: true,
           rsync_mibs: true,
           rsync_mibs_dir: '/etc/mibs_here',
           rsync_dlmod_dir: '/etc/dlmod_there',
           dlmods: ['mod1', 'mod2']
            }
          end

          it_behaves_like 'a structured module'
          it { is_expected.to contain_class('simp_snmpd::config').that_comes_before('Class[simp_snmpd::rsync]') }
          it { is_expected.to contain_file('/etc/mibs_here') }
          it { is_expected.to contain_file('/etc/dlmod_there') }
          it { is_expected.to contain_file('/etc/snmp/simp_snmpd.d/dlmod.conf') }
        end
        context 'simp_snmp class with set_system_info false' do
          let(:params) do
            {
              system_info: false,
            }
          end

          it { is_expected.not_to contain_class('simp_snmpd::config::system_info') }
        end
        context 'simp_snmp class with simp parameters set to true' do
          let(:params) do
            {
              firewall: true,
           tcpwrappers: true,
           syslog: true,
           logrotate: true,
            }
          end

          it_behaves_like 'a structured module'
          it { is_expected.to contain_class('simp_snmpd::config::tcpwrappers') }
          it { is_expected.to contain_class('simp_snmpd::config::firewall') }
          it { is_expected.to contain_class('simp_snmpd::config::logging') }
          it { is_expected.to create_rsyslog__rule__local('XX_snmpd') }
          it { is_expected.to create_logrotate__rule('snmpd') }
        end
        context 'with some parameters set' do
          let(:params) do
            {
              manage_client: true,
           include_userdir: true,
            }
          end

          it_behaves_like 'a structured module'
          it {
            is_expected.to contain_class('snmp').with({
                                                        manage_client: 'true',
              snmp_config: [
                'defVersion  3',
                'defSecurityModel usm',
                'defSecurityLevel authPriv',
                'defAuthType SHA',
                'defPrivType AES',
                'mibdirs /usr/share/snmp/mibs:/usr/share/snmp/mibs',
              ]
                                                      })
          }
          it {
            is_expected.to contain_file('/etc/snmp/snmpd.d').with({
                                                                    ensure: 'directory'
                                                                  })
          }
          it {
            is_expected.to contain_class('snmp').with({
                                                        snmpd_config: [
                                                          'includeDir /etc/snmp/simp_snmpd.d',
                                                          'includeDir /etc/snmp/snmpd.d',
                                                        ],
             manage_client: true,
                                                      })
          }
        end
        context 'with manage users' do
          let(:params) do
            {
              snmpd_gid: 9999,
           snmpd_uid: 9999,
           manage_snmpd_user: true,
           manage_snmpd_group: true,
           service_config_dir_owner: 'snmp',
           service_config_dir_group: 'snmp'
            }
          end

          it { is_expected.to contain_class('simp_snmpd::install::snmpduser') }
          it { is_expected.to create_group('snmp') }
          it { is_expected.to create_user('snmp') }
          it {
            is_expected.to contain_class('snmp').with({
                                                        service_config_dir_group: 'snmp',
               service_config_dir_owner: 'snmp',
                                                      })
          }
        end
        context 'with fips on auth type set to MD5' do
          let(:params) do
            {
              fips: true,
           defauthtype: 'MD5',
            }
          end

          it { is_expected.to compile.and_raise_error(%r{Invalid default authentication type}) }
        end
        context 'with fips on priv type set to DES' do
          let(:params) do
            {
              fips: true,
           defauthtype: 'SHA',
           defprivtype: 'DES'
            }
          end

          it { is_expected.to compile.and_raise_error(%r{Invalid default privacy type}) }
        end
        context 'with fips on and MD5 as authtype in user array' do
          let(:params) do
            {
              fips: true,
           v3_users_hash: {
             baduser: {
               authtype: 'MD5',
               authpass: 'Passw0rdPassword'
             }
           }
            }
          end

          it { is_expected.to compile.and_raise_error(%r{failed to create user}) }
        end
      end
    end
  end
end
