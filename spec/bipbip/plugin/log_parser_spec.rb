require 'bipbip'
require 'bipbip/plugin/log_parser'

describe Bipbip::Plugin::LogParser do

  let(:plugin) { Bipbip::Plugin::LogParser.new('log-parser', {
      'name' => 'inactive_oom_killer',
      'uri' => 'file://localhost' + File.expand_path('../../../testdata/sample_logs/sample.log', __FILE__),
      'regexp_text' => 'oom_killer',
      'regexp_timestamp' => '^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}\b'
    }, 10)
  }

  it 'should collect data' do
    data = plugin.monitor

    data['inactive_oom_killer'].should be_instance_of(Fixnum)
    data['inactive_oom_killer'].should eq(4)
  end
end
