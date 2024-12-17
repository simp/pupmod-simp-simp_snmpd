require 'spec_helper'

describe 'simp_snmpd::grouplist' do
  context 'With valid params' do
    it 'grouplist returns an array' do
      args = {
        'group1' => {
          'secname' => [ 'user1', 'user2']
        },
                'group2' => {
                  'secname' => 'user3',
                  'model' => 'tsm'
                },
      }
      retval = [
        'group1 usm user1',
        'group1 usm user2',
        'group2 tsm user3',
      ]
      is_expected.to run.with_params(args, 'usm').and_return(retval)
    end
    it 'grouplist can handle an empty group hash and removes it from the list' do
      args = {
        'group1' => {
          'secname' => [ 'user1', 'user2']
        },
                'group2' => {}
      }
      retval = [
        'group1 usm user1',
        'group1 usm user2',
      ]
      is_expected.to run.with_params(args, 'usm').and_return(retval)
    end
    it 'returns an error with with incorrect params' do
      args = { 'errorgroup' =>
               { 'secname' => 'user1',
                 'model' => 'oid' } }
      is_expected.to run.with_params(args, 'tsm').and_raise_error(%r{Badly formed group})
    end
  end
end
