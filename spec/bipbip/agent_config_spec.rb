require 'bipbip'

describe Bipbip::Agent do


  describe "loading up YAML config with includes" do
    before(:each) do
      Bipbip.logger = double('logger')
    end
    it 'should set up storages and plugins and inherit the base frequency unless overwritten' do
      bipbip = Bipbip::Agent.new("#{File.dirname(__FILE__)}/../testdata/sample_base.yml")
      
      bipbip.instance_variable_get(:@storages).count.should eq(1)
      bipbip.instance_variable_get(:@storages).first.name.should eq 'copperegg'
      bipbip.instance_variable_get(:@storages).first.config['api_key'].should eq 'MOCK_APIKEY'
      
      sorted_plugins = bipbip.instance_variable_get(:@plugins).sort {|a,b| a.name <=> b.name }
      sorted_plugins.count.should eq(3)
      
      sorted_plugins[0].name.should eq 'mysql'
      sorted_plugins[0].frequency.should eq 15  # default frequency
      
      sorted_plugins[1].name.should eq 'redis'
      sorted_plugins[1].frequency.should eq 60  # overwriten to be longer

      sorted_plugins[2].name.should eq 'resque'
      sorted_plugins[2].frequency.should eq 15  # default frequency
      sorted_plugins[2].config['namespace'].should eq 'resque:prefix'

      Bipbip.logger = nil
    end
  end

end
