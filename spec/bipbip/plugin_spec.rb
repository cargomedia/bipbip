require 'bipbip'

describe Bipbip::Plugin do
  it 'should store configuration' do
    plugin = Bipbip::Plugin.new('my-plugin', { foo: 'my foo' }, 2, %w(tag1 tag2), 'my metric')

    plugin.name.should eq('my-plugin')
    plugin.config.should eq(foo: 'my foo')
    plugin.frequency.should eq(2)
    plugin.tags.should eq(%w(tag1 tag2))
    plugin.metric_group.should eq('my metric')
  end

  it 'should create instances from plugins' do
    plugin = Bipbip::Plugin.new('my-plugin', { foo: 'my foo' }, 2, %w(tag1 tag2), 'my metric')
    plugin2 = Bipbip::Plugin.factory_from_plugin(plugin)

    plugin2.should_not eq(plugin)
    plugin2.name.should eq('my-plugin')
    plugin2.config.should eq(foo: 'my foo')
    plugin2.frequency.should eq(2)
    plugin2.tags.should eq(%w(tag1 tag2))
    plugin2.metric_group.should eq('my metric')
  end
end
