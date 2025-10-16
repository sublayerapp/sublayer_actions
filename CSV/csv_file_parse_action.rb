require 'csv'

# Description: Sublayer::Action responsible for parsing CSV files and extracting data.
# This action is useful for feeding tabular data directly into Sublayer workflows or for other processing needs.
#
# It is initialized with a file_path and optionally headers (indicating whether the CSV file contains headers).
# It returns an array of hashes where each hash represents a row in the CSV file, with keys as column headers if headers are present.
#
# Example usage: When you want to parse a CSV file's data to send it into an AI model or process it further.

class CSVFileParseAction < Sublayer::Actions::Base
  def initialize(file_path:, headers: true)
    @file_path = file_path
    @headers = headers
  end

  def call
    begin
      parse_csv_file
    rescue CSV::MalformedCSVError => e
      error_message = "CSV file is malformed: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue IOError => e
      error_message = "Error reading CSV file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error parsing CSV file: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def parse_csv_file
    options = { headers: @headers, return_headers: false }
    rows = []

    CSV.foreach(@file_path, options) do |row|
      rows << (row.to_hash if @headers) || row.to_a
    end

    Sublayer.configuration.logger.log(:info, "Successfully parsed CSV file: #{@file_path}")
    rows
  end
end