require 'spec_helper'

describe 'simp_snmpd::viewlist' do
  context 'With valid params' do
    it 'returns an array and removes views with no keys like empty view' do
      args = { 'first_view' =>
               { 'included' => '.1.2.3.4',
                 'excluded' => ['6.7.5.6', '.9'] },
             'empty_view' => {},
             'second_view' =>
               { 'included' => 'My::Mib', } }
      retval = [
        'first_view included .1.2.3.4',
        'first_view excluded 6.7.5.6',
        'first_view excluded .9',
        'second_view included My::Mib',
      ]
      is_expected.to run.with_params(args).and_return(retval)
    end
    it 'returns an error with with incorrect params' do
      args = { 'error_view' =>
               { 'not_included' => 'oid' } }
      is_expected.to run.with_params(args).and_raise_error(%r{Badly formed view_hash})
    end
  end
end
