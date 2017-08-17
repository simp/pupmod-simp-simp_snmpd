require 'spec_helper'

describe 'simp_snmpd::grouplist' do
  context 'With valid params' do

    it 'returns an array' do
      args = {"group1" =>
               { "secname" => [ 'user1', 'user2']
              },
              "group2" =>
                { "secname" => "user3",
                  "model" => "tsm"
                },
              "group3" => {}
             }
      retval = [
             'group group1 usm user1',
             'group group1 usm user2',
             'group group2 tsm user3',
             ]
      is_expected.to run.with_params(args,"usm").and_return(retval)
    end
    it 'returns an error with with incorrect params' do
      args = { "errorgroup" =>
               { "secname" => "user1",
                 "model" => "oid" }
             }
      is_expected.to  run.with_params(args,"tsm").and_raise_error(/Badly formed group/)
    end
  end
end
