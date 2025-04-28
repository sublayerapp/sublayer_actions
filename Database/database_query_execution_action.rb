require 'pg'

# Description: Sublayer::Action responsible for executing a specified SQL query on a connected database.
# It facilitates automation of data retrieval and processing tasks within Sublayer workflows.
#
# It is initialized with a connection string and an SQL query.
# It returns the query result or handles errors if they occur.
#
# Example usage: When you want to retrieve data from a database as part of a Sublayer workflow for further processing or analysis.

class DatabaseQueryExecutionAction < Sublayer::Actions::Base
  def initialize(connection_string:, sql_query:)
    @connection_string = connection_string
    @sql_query = sql_query
    @logger = Sublayer.configuration.logger
  end

  def call
    begin
      connection = PG.connect(@connection_string)
      result = connection.exec(@sql_query)
      parse_result(result)
    rescue PG::Error => e
      error_message = "SQL query execution error: #{e.message}"
      @logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      connection.close if connection
    end
  end

  private

  def parse_result(result)
    result.map { |row| row }
  end
end