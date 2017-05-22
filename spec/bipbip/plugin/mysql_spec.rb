require 'bipbip'
require 'bipbip/plugin/mysql'

describe Bipbip::Plugin::Mysql do
  let(:plugin) { Bipbip::Plugin::Mysql.new('mysql', { 'hostname' => 'localhost', 'port' => 3306, 'username' => 'travis', 'password' => '' }, 10) }

  it 'should collect data' do
    data = plugin.monitor

    data['Com_select'].should be_kind_of(Integer)
    data['Processlist_Locked'].should be_kind_of(Integer)
    data['Seconds_Behind_Master'].should be_kind_of(Integer)
    data['Slave_running'].should be_kind_of(Integer)
  end
end
