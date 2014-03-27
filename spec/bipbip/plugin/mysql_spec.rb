require 'bipbip'
require 'bipbip/plugin/mysql'

describe Bipbip::Plugin::Mysql do
  let(:plugin) { Bipbip::Plugin::Mysql.new('mysql', {'hostname' => 'localhost', 'port' => 3306, 'username' => 'travis', 'password' => ''}, 10) }

  it 'should collect data' do
    data = plugin.monitor

    data['Com_select'].should be_instance_of(Fixnum)
    data['Processlist_Locked'].should be_instance_of(Fixnum)
    data['Seconds_Behind_Master'].should be_instance_of(Fixnum)
  end
end
