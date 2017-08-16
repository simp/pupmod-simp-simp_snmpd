require 'spec_helper'

describe 'get_ports' do
  # Trusted Node Data
  context 'with trusted node data' do
    it do
      view_hash  = {
        'first_view' => {
          'included' => '.1.2.3.4',
          'excluded' => ['6.7.5.6', '.9']
        }
      }
      expet( subject.call([view_hash]) ).to match_array(['view first_view included .1.2.3.4','view first_view  excluded 6.7.5.6', 'view first_view  excluded .9'])
     end
  end
end
