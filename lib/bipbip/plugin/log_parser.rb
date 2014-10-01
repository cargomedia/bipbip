require 'stringio'
require 'uri'

module Bipbip

  class Plugin::LogParser < Plugin
    def metrics_schema
      metric_list = [
          {:name => 'All_Logs_ok', :type => 'gauge', :unit => 'Boolean'}
      ]

      config['sources'].each do |name, config|
        metric_list.push({:name => name, :type => 'gauge', :unit => 'Boolean'})
      end

      metric_list
    end

    def monitor
      sources = config['sources']

      data = Hash.new(0)

      data['All_Logs_ok'] = 1

      sources.each do |name, config|
        source_data = source_data(config['uri'])
        options = source_options(config['uri'], config)

        parsed = source_parse(source_data, config['regexp_text'], options)

        data[name] = parsed.nil?
      end

      data
    end

    private

    def source_parse(data, regexp, options)
      if options.key?('regexp_timesstamp') and options.key?('age_max')
        regexp_timestamp = Regexp.new(options['regexp_timesstamp'])
        age_max = options['age_max'].to_i
      end

      data =~ Regexp.new(regexp)
    end

    def source_options(uri, config)
      source = uri(uri)
      type = source.scheme

      options = config['file_options'] if type == 'file'
      options = config['http_options'] if type == 'http'

      options
    end

    def source_data(uri)
      source = uri(uri)
      type = source.scheme

      data = file(source.path) if type == 'file'
      data = http(source) if type == 'http'

      data
    end

    def uri(uri)
      uri = URI(uri)
      raise 'URI is not uniform or valid' unless ['file', 'http'].include? uri.scheme

      uri
    end

    def file(path)
      raise 'File does not exist' unless File.exists?(path)

      File.read(path)
    end

    def http(uri, type = 'get', data = {})
      raise 'Unknown http request type' unless ['get', 'post'].include? type
    end
  end
end
