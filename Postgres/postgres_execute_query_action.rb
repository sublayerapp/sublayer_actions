require 'pg'

# Description: Sublayer::Action responsible for executing a custom SQL query against a Postgres database and returning the result set as a list of dictionaries.
#
# It is initialized with a connection string and a SQL query.
# It returns an array of hashes, where each hash represents a row in the result set.
#
# Example usage: When you need to retrieve data from a Postgres database to use in a Sublayer::Generator prompt or other AI workflow.

class PostgresExecuteQueryAction < Sublayer::Actions::Base
  def initialize(connection_string:, query:)
    @connection_string = connection_string
    @query = query
  end

  def call
    begin
      connection = PG.connect(@connection_string)
      result = connection.exec(@query)
      data = result.map { |row| row }
      Sublayer.configuration.logger.log(:info, "Successfully executed query against Postgres database.")
      data
    rescue PG::Error => e
      error_message = "Error executing query against Postgres database: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      connection&.close # Ensure the connection is closed
    end
  end
end