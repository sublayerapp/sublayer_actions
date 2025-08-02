# Description: Sublayer::Action responsible for parsing structured data (CSV, JSON, YAML) from a string or file and returning it as a Ruby object (Hash or Array).
#
# This action leverages gems like CSV, JSON, and YAML to parse data and provides a unified interface for Sublayer workflows.
#
# It is initialized with either a data string or a file path, and the data format (csv, json, or yaml).
# It returns a Ruby Hash or Array representing the parsed data.
#
# Example usage: When you need to process data from a CSV file, an API returning JSON, or a YAML configuration file within a Sublayer::Generator prompt.

require 'csv'
require 'json'
require 'yaml'

class ParseStructuredDataAction < Sublayer::Actions::Base
  def initialize(data: nil, file_path: nil, format: 'json')
    raise ArgumentError, 'Either data or file_path must be provided' unless data || file_path
    raise ArgumentError, 'Both data and file_path cannot be provided' if data && file_path
    raise ArgumentError, "Invalid format: \#{format}. Must be one of: csv, json, yaml" unless %w[csv json yaml].include?(format)

    @data = data
    @file_path = file_path
    @format = format.downcase
  end

  def call
    begin
      data = @data || File.read(@file_path)
      parse_data(data, @format)
    rescue Errno::ENOENT => e
      error_message = "File not found: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error parsing data: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def parse_data(data, format)
    case format
    when 'csv'
      parse_csv(data)
    when 'json'
      parse_json(data)
    when 'yaml'
      parse_yaml(data)
    end
  end

  def parse_csv(data)
    CSV.parse(data, headers: true).map(&:to_h)
  end

  def parse_json(data)
    JSON.parse(data)
  end

  def parse_yaml(data)
    YAML.safe_load(data)
  end
end