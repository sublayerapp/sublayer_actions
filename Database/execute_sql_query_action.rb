require 'sqlite3'
require 'json'
require 'csv'

# Description: Sublayer::Action responsible for executing a SQL query against a database and returning the results.
# It supports SQLite databases and can return results in JSON or CSV format.
#
# It is initialized with database connection details (path to the SQLite database file), a SQL query string, and an optional output format (JSON or CSV).
# It returns the query results as a JSON object or CSV string.
#
# Example usage: When you want to query a local database and use the results in a Sublayer::Generator.

class ExecuteSqlQueryAction < Sublayer::Actions::Base
  def initialize(db_path:, query:, output_format: 'json')
    @db_path = db_path
    @query = query
    @output_format = output_format.downcase
    unless ['json', 'csv'].include?(@output_format)
      raise ArgumentError, "Invalid output_format: #{@output_format}. Must be 'json' or 'csv'."
    end
  end

  def call
    begin
      db = SQLite3::Database.new(@db_path)
      results = db.execute(@query)
      db.close

      case @output_format
      when 'json'
        column_names = results.first.is_a?(Array) ? results.first.map { |_,name| name } : []
        json_result = results.map { |row| Hash[column_names.zip(row)] }.to_json
        Sublayer.configuration.logger.log(:info, "SQL query executed successfully. Result as JSON.")
        json_result
      when 'csv'
        csv_string = CSV.generate do |csv|
          results.each { |row| csv << row }
        end
        Sublayer.configuration.logger.log(:info, "SQL query executed successfully. Result as CSV.")
        csv_string
      end
    rescue SQLite3::Exception => e
      error_message = "Error executing SQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error processing SQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end