require 'bipbip'
require 'bipbip/plugin/log_parser'

describe Bipbip::Plugin::LogParser do

  let(:plugin1) { Bipbip::Plugin::LogParser.new('log-parser', {
      'name' => 'oom_killer_activity',
      'uri' => 'file://localhost' + File.expand_path('../../../testdata/sample_logs/sample.log', __FILE__),
      'regexp_text' => 'oom_killer',
      'regexp_timestamp' => '^\d{4}-\d{2}-\d{2}T\d{2}\:\d{2}\:\d{2}\b'
    }, 10)
  }

  let(:plugin2) { Bipbip::Plugin::LogParser.new('log-parser', {
      'name' => 'root_activity',
      'uri' => 'file://localhost' + File.expand_path('../../../testdata/sample_logs/sample.log', __FILE__),
      'regexp_text' => 'root.*login$'
  }, 10)
  }

  it 'should collect data' do
    data1 = plugin1.monitor
    data2 = plugin2.monitor

    data = data1.merge(data2)

    data['oom_killer_activity'].should be_instance_of(Fixnum)
    data['oom_killer_activity'].should eq(7)

    data['root_activity'].should be_instance_of(Fixnum)
    data['root_activity'].should eq(1)
  end
end
