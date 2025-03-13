# Description: Sublayer::Action responsible for executing a SQL query against a specified database and returning the results as a JSON string.
#
# It is initialized with a database connection string and a SQL query.
# It returns the results of the query as a JSON string.
#
# Example usage: When you want to retrieve data from a database to provide context to an LLM.

require 'sqlite3'
require 'json'

class SqlQueryExecutionAction < Sublayer::Actions::Base
  def initialize(db_connection_string:, sql_query:)
    @db_connection_string = db_connection_string
    @sql_query = sql_query
  end

  def call
    begin
      db = SQLite3::Database.new @db_connection_string
      results = db.execute @sql_query
      db.close

      # Convert results to a more easily digestable format
      column_names = results.first.is_a?(Array) ? results.first.map { |_, key| key } : results.first.keys if results.any?

      # Format results into a hash
      formatted_results = results.map do |row|
        Hash[column_names.zip(row)]
      end

      # Convert to JSON
      json_results = formatted_results.to_json

      Sublayer.configuration.logger.log(:info, "Successfully executed SQL query")
      json_results
    rescue SQLite3::Exception => e
      error_message = "Error executing SQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error converting results to JSON: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end