require 'bipbip'
require 'bipbip/plugin/log_parser'

describe Bipbip::Plugin::LogParser do

  let(:plugin) { Bipbip::Plugin::LogParser.new('log-parser', {
      'sources' => {
          'active_oom_killer' => {
              'uri' => 'file://localhost' + File.expand_path('../../../testdata/logger/sample.log', __FILE__),
              'regexp_text' => 'oom_killer',
              'file_options' => {
                'regexp_timestamp' => '^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}\b',
                'age_max' => 3600
              }
          },
          'active_root' => {
              'uri' => 'file://localhost' + File.expand_path('../../../testdata/logger/sample.log', __FILE__),
              'regexp_text' => 'root login',
              'file_options' => {
                  'regexp_timestamp' => '^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}\b',
                  'age_max' => 100
              }
          }
      }
    }, 10)
  }

  it 'should collect data' do
    data = plugin.monitor

    data['All_Logs_ok'].should be_instance_of(Fixnum)
    data['All_Logs_ok'].should eq(0)

    data['active_oom_killer'].should be_instance_of(Fixnum)
    data['active_oom_killer'].should eq(0)

    data['active_root'].should be_instance_of(Fixnum)
    data['active_root'].should eq(1)
  end
end
