require 'bipbip'
require 'bipbip/plugin/log_parser'
require 'tempfile'

describe Bipbip::Plugin::LogParser do
  let(:file) do
    Tempfile.new('bipbip-logparser-spec')
  end

  let(:plugin) do
    config = {
      'path' => file.path,
      'matchers' => [
        {
          'name' => 'test',
          'regexp' => 'te+st'
        }
      ]
    }
    Bipbip::Plugin::LogParser.new('log-parser', config, 10)
  end

  it 'should match appended content' do
    plugin.monitor
    File.open(file.path, 'a') do |f|
      f.puts 'my test'
      f.puts 'my second test'
      f.puts 'mega'
    end
    plugin.monitor.should eq('test' => 2)
  end

  it 'should match written content' do
    plugin.monitor

    File.open(file.path, 'w') do |f|
      f.puts 'my test'
      f.puts 'my second test'
      f.puts 'my third test'
    end
    plugin.monitor.should eq('test' => 3)

    File.open(file.path, 'w') do |f|
      f.puts 'my test'
    end
    plugin.monitor.should eq('test' => 0)

    File.open(file.path, 'w') do |f|
      f.puts 'my test'
      f.puts 'my second test'
    end
    plugin.monitor.should eq('test' => 1)
  end

  it 'should re-watch the file after deletion' do
    plugin.monitor

    path = file.path
    file.close
    File.unlink(path)

    plugin.monitor.should eq('test' => 0)

    File.open(path, 'w') do |f|
      f.write('')
    end

    plugin.monitor.should eq('test' => 0)

    File.open(path, 'a') do |f|
      f.puts 'my test'
    end
    plugin.monitor.should eq('test' => 1)
  end

  it 'should re-watch the file after moving' do
    plugin.monitor

    path = file.path
    path_new = Tempfile.new('bipbip-logparser-spec').path
    File.rename(path, path_new)

    plugin.monitor.should eq('test' => 0)

    File.open(path, 'w') do |f|
      f.write('')
    end

    plugin.monitor.should eq('test' => 0)

    File.open(path, 'a') do |f|
      f.puts 'my test'
    end
    plugin.monitor.should eq('test' => 1)
  end

  it 'should raise if unable to read file' do
    file.chmod(0000)
    expect { plugin.monitor }.to raise_error(RuntimeError, /Cannot read file/)
  end
end
