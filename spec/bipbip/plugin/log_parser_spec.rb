require 'bipbip'
require 'bipbip/plugin/log_parser'

describe Bipbip::Plugin::LogParser do
  let(:plugin) { Bipbip::Plugin::LogParser.new('log-parser', {
      'sources' => {
          'active_oom_killer' => {
              'uri' => 'file://localhost/tmp/bipbip.log',
              'regexp_text' => 'oom_killer',
              'file_options' => {
                'regexp_timestamp' => 'oom_killer',
                'age_max' => 1000
              }
          }
      }
    }, 10)
  }

  it 'should collect data' do
    data = plugin.monitor

    p data

    data['All_Logs_ok'].should be_instance_of(Fixnum)
  end
end
