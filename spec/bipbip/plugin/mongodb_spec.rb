require 'bipbip'
require 'bipbip/plugin/mongodb'

describe Bipbip::Plugin::Mongodb do
  let(:plugin) { Bipbip::Plugin::Mongodb.new('mongodb', {'host' => 'localhost', 'port' => 27017}, 10) }

  it 'should collect data' do
    data = plugin.monitor

    plugin.metrics_schema.each do |metric|
      puts metric[:name], ':', data[metric[:name]]
    end

  end
end
