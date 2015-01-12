require 'pathname'
require 'yaml'

module Bipbip

  class Plugin::Puppet < Plugin

    def metrics_schema
      [
          {:name => 'last_run_total_time', :type => 'gauge', :unit => 'Seconds'},
          {:name => 'last_run_age', :type => 'gauge', :unit => 'Seconds'},
          {:name => 'has_events', :type => 'gauge', :unit => 'Boolean'},
          {:name => 'has_resources', :type => 'gauge', :unit => 'Boolean'},
          {:name => 'has_changes', :type => 'gauge', :unit => 'Boolean'},
          {:name => 'events_failure_count', :type => 'gauge', :unit => 'Events'},
          {:name => 'events_success_count', :type => 'gauge', :unit => 'Events'},
          {:name => 'events_total_count', :type => 'gauge', :unit => 'Events'},
          {:name => 'resources_failed_count', :type => 'gauge', :unit => 'Resources'},
          {:name => 'resources_skipped_count', :type => 'gauge', :unit => 'Resources'},
          {:name => 'resources_total_count', :type => 'gauge', :unit => 'Resources'},
          {:name => 'changes_total_count', :type => 'gauge', :unit => 'Changes'},
      ]
    end

    def monitor
      puppet_report = last_run_summary

      report_age = Time.new.to_i - puppet_report['time']['last_run'].to_i
      has_events = puppet_report.has_key?('events')
      has_resources = puppet_report.has_key?('resources')
      has_changes = puppet_report.has_key?('changes')
      {
          'last_run_total_time' => puppet_report['time']['total'].to_i,
          'last_run_age' => report_age,
          'has_events' => (has_events ? 1 : 0),
          'has_resources' => (has_resources ? 1 : 0),
          'has_changes' => (has_resources ? 1 : 0),
          'events_failure_count' => (has_events ? puppet_report['events']['failure'].to_i : 0),
          'events_success_count' => (has_events ? puppet_report['events']['success'].to_i : 0),
          'events_total_count' => (has_events ? puppet_report['events']['total'].to_i : 0),
          'resources_failed_count' => (has_resources ? puppet_report['resources']['failed'].to_i : 0),
          'resources_skipped_count' => (has_resources ? puppet_report['resources']['skipped'].to_i : 0),
          'resources_total_count' => (has_resources ? puppet_report['resources']['total'].to_i : 0),
          'changes_total_count' => (has_changes ? puppet_report['changes']['total'].to_i : 0),
      }
    end

    private

    def last_run_summary
      YAML.load_file(Pathname.new('/var/lib/puppet/state/last_run_summary.yaml'))
    end
  end
end
