require 'spec_helper'

describe 'simp_snmpd' do
  shared_examples_for "a structured module" do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('simp_snmpd') }
    it { is_expected.to contain_class('simp_snmpd') }
    it { is_expected.to contain_class('simp_snmpd::install').that_comes_before('Class[simp_snmpd::config]') }
    it { is_expected.to contain_class('simp_snmpd::config') }
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
          it { is_expected.to contain_class('simp_snmpd').with_trusted_nets(['127.0.0.1']) }
        end
      end
    end
  end
end
