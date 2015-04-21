require 'bipbip'

describe Bipbip::Config do


  describe "loading up YAML config with includes" do
    it 'should set up storages and plugins and inherit the base frequency unless overwritten' do
      config = Bipbip::Config.factory_from_file("#{File.dirname(__FILE__)}/../testdata/sample_base.yml")

      config.storages.count.should eq(1)
      config.storages.first.name.should eq 'copperegg'
      config.storages.first.config['api_key'].should eq 'MOCK_APIKEY'

      sorted_plugins = config.plugins.sort { |a, b| a.name <=> b.name }
      sorted_plugins.count.should eq(3)

      sorted_plugins[0].name.should eq 'mysql'
      sorted_plugins[0].frequency.should eq(15) # default frequency
      sorted_plugins[0].tags.should eq(['foo', 'bar'])

      sorted_plugins[1].name.should eq 'redis'
      sorted_plugins[1].frequency.should eq(60) # overwriten to be longer
      sorted_plugins[1].tags.should eq(['foo', 'bar', 'hello'])

      sorted_plugins[2].name.should eq 'resque'
      sorted_plugins[2].frequency.should eq(15) # default frequency
      sorted_plugins[2].config['namespace'].should eq 'resque:prefix'
      sorted_plugins[2].tags.should eq(['foo', 'bar'])
    end
  end

end
