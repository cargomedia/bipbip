require 'bipbip'
require 'bipbip/plugin/command_status'
require 'tempfile'

describe Bipbip::Plugin::CommandStatus do
  command = 'echo "foo" > /dev/stdout; echo "bar" > /dev/stderr; exit 42;'

  let(:logger_file) { Tempfile.new('bipbip-mock-logger') }
  let(:logger) { Logger.new(logger_file.path) }
  let(:plugin) { Bipbip::Plugin::CommandStatus.new('cmd-status', { 'command' => command }, 0.1) }
  let(:agent) { Bipbip::Agent.new(Bipbip::Config.new([plugin], [], logger)) }

  it 'should collect status:42' do
    thread = Thread.new { agent.run }
    sleep 0.3

    lines = logger_file.read.lines
    expect(lines.count { |l| /INFO.*: foo/.match(l) }).to be >= 1
    expect(lines.count { |l| /ERROR.*: bar/.match(l) }).to be >= 1
    expect(lines.count { |l| l.include?('Data: {:status=>42}') }).to be >= 1
    thread.exit
  end
end
