require 'pathname'
require 'yaml'

module Bipbip
  class Plugin::Puppet < Plugin
    def metrics_schema
      [
        { name: 'report_ok', type: 'gauge', unit: 'Boolean' },
        { name: 'last_run_total_time', type: 'gauge', unit: 'Seconds' },
        { name: 'last_run_age', type: 'gauge', unit: 'Seconds' },
        { name: 'events_failure_count', type: 'gauge', unit: 'Events' },
        { name: 'events_success_count', type: 'gauge', unit: 'Events' },
        { name: 'events_total_count', type: 'gauge', unit: 'Events' },
        { name: 'resources_failed_count', type: 'gauge', unit: 'Resources' },
        { name: 'resources_skipped_count', type: 'gauge', unit: 'Resources' },
        { name: 'resources_total_count', type: 'gauge', unit: 'Resources' },
        { name: 'changes_total_count', type: 'gauge', unit: 'Changes' }
      ]
    end

    def monitor
      puppet_report = last_run_summary

      report_age = Time.new.to_i - puppet_report['time']['last_run'].to_i
      has_events = puppet_report.key?('events')
      has_resources = puppet_report.key?('resources')
      has_changes = puppet_report.key?('changes')

      metrics = {
        'report_ok' => ((has_events && has_changes && has_resources) ? 1 : 0),
        'last_run_total_time' => puppet_report['time']['total'].to_i,
        'last_run_age' => report_age
      }

      if has_events
        metrics['events_failure_count'] = puppet_report['events']['failure'].to_i
        metrics['events_success_count'] = puppet_report['events']['success'].to_i
        metrics['events_total_count'] = puppet_report['events']['total'].to_i
      end

      if has_resources
        metrics['resources_failed_count'] = puppet_report['resources']['failed'].to_i
        metrics['resources_skipped_count'] = puppet_report['resources']['skipped'].to_i
        metrics['resources_total_count'] = puppet_report['resources']['total'].to_i
      end

      if has_changes
        metrics['changes_total_count'] = puppet_report['changes']['total'].to_i
      end

      metrics
    end

    private

    def last_run_summary
      YAML.load_file(Pathname.new('/var/lib/puppet/state/last_run_summary.yaml'))
    end
  end
end
