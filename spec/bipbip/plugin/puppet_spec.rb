require 'bipbip'
require 'bipbip/plugin/puppet'
require 'yaml'

describe Bipbip::Plugin::Puppet do
  let(:plugin) do
    Bipbip::Plugin::Puppet.new('puppet', {}, 10)
  end

  it 'should collect data' do
    puppet_yaml = <<YAML
---
    version:
        config: 1420794150
        puppet: "3.7.3"
    resources:
        changed: 99
        failed: 900
        failed_to_restart: 0
        out_of_sync: 0
        restarted: 0
        scheduled: 0
        skipped: 0
        total: 999
    time:
        augeas: 0.8596624150000001
        config_retrieval: 9.024674286
        exec: 2.391107351
        file: 0.23048283800000002
        filebucket: 9.2722e-05
        group: 0.000398085
        host: 0.004328768
        mongodb_collection: 0.380806017
        mongodb_database: 0.509239221
        mongodb_user: 0.888489175
        package: 0.6635092269999997
        resources: 8.8065e-05
        schedule: 0.000489968
        service: 1.022823853
        ssh_authorized_key: 0.0012527
        sshkey: 0.007716162
        total: 99.999999
        user: 0.001077532
        last_run: 1420794191
    changes:
        total: 199
    events:
        failure: 9
        success: 99
        total: 108
YAML

    allow(plugin).to receive(:last_run_summary).and_return(YAML.load(puppet_yaml))

    data = plugin.monitor

    data['report_ok'].should eq(1)
    data['last_run_total_time'].should eq(99)
    data['last_run_age'].should be_instance_of(Integer)

    data['events_total_count'].should eq(108)
    data['resources_total_count'].should eq(999)
    data['changes_total_count'].should eq(199)
  end
end
