require 'pg'

# Description: Sublayer::Action responsible for running SQL queries on a PostgreSQL database.
# This action allows integration with PostgreSQL databases directly within Sublayer workflows.
#
# Initialized with a connection string and an SQL query, it returns the query results.
#
# Example usage: When you want to fetch data from a PostgreSQL database to use in further Sublayer processing.

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(connection_string:, sql_query:)
    @connection_string = connection_string
    @sql_query = sql_query
  end

  def call
    begin
      connection = PG.connect(@connection_string)
      result = connection.exec(@sql_query)
      Sublayer.configuration.logger.log(:info, "Successfully executed query")
      format_results(result)
    rescue PG::Error => e
      error_message = "Database query failed: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      connection.close if connection
    end
  end

  private

  def format_results(result)
    result.map do |row|
      row
    end
  end
end