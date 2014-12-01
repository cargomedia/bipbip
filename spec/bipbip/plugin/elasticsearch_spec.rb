require 'bipbip'
require 'bipbip/plugin/elasticsearch'

describe Bipbip::Plugin::Elasticsearch do
  let(:plugin) { Bipbip::Plugin::Elasticsearch.new('elasticsearch', {'hosts' => ['10.55.40.156:9200']}, 10) }

  it 'should collect some data' do

    data = plugin.monitor
    data['active_primary_shards'].should eq(7)
    data['active_shards'].should eq(7)
  end

end
