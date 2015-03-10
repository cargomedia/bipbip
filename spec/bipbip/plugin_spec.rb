require 'bipbip'

describe Bipbip::Plugin do


  it 'should store configuration' do
    plugin = Bipbip::Plugin.new('my-plugin', {:foo => 'my foo'}, 2, ['tag1', 'tag2'], 'my metric')

    plugin.name.should eq('my-plugin')
    plugin.config.should eq({:foo => 'my foo'})
    plugin.frequency.should eq(2)
    plugin.tags.should eq(['tag1', 'tag2'])
    plugin.metric_group.should eq('my metric')
  end

end
