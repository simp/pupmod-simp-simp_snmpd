require 'spec_helper'

describe 'simp_snmpd::accesslist' do
  context 'With valid params' do
    it 'returns the correct defaults' do
      args = { 'access1' =>
                { 'view' => {
                    'read' => 'myview'
                  },
                'groups' => 'group1' } }
      retval = [
        'group1 "" usm priv exact myview none none',
      ]
      is_expected.to run.with_params(args, 'usm', 'priv').and_return(retval)
    end
    it 'returns the correct error if view is not a hash' do
      args = { 'access1' =>
                { 'view'    => 'myview',
                  'groups'  => ['group1', 'group2'],
                  'level'   => 'auth',
                  'context' => 'c',
                  'prefix'  => 'prefix' } }
      is_expected.to run.with_params(args, 'usm', 'priv').and_raise_error(%r{expects a hash})
    end
    it 'returns the correct access list and can handle empty list' do
      args = {
        'access1' => {
          'view' => {
            'write' => 'myview'
          },
           'groups'  => ['group1', 'group2'],
           'level'   => 'auth',
           'context' => 'c',
           'prefix'  => 'prefix'
        },
                'empty' => {}
      }
      retval = [
        'group1 c usm auth prefix none myview none',
        'group2 c usm auth prefix none myview none',
      ]

      is_expected.to run.with_params(args, 'usm', 'priv').and_return(retval)
    end
    it 'returns an error with with incorrect params' do
      args = { 'access1' =>
                { 'level' => 'priv',
                  'model' => 'tsm' } }
      is_expected.to run.with_params(args, 'usm', 'priv').and_raise_error(%r{missing either view or groups})
    end
    it 'returns an error with with incorrect keys' do
      args = {
        'access1' => {
          'view' => {
            'write' => 'myview'
          },
           'groups' => ['group1', 'group2'],
           'level' => 'auth',
           'mycontext' => 'c',
           'prefix' => 'prefix'
        },
      }
      is_expected.to run.with_params(args, 'usm', 'priv').and_raise_error(%r{invalid key})
    end
  end
end
