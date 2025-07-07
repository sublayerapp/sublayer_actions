require 'pg'

# Description: Sublayer::Action responsible for fetching data from a specified database using SQL queries.
# This action can be used to retrieve data for processing in Sublayer workflows.
#
# It is initialized with a database connection configured through parameters like host, dbname, user, and password
# and an SQL query to execute. It returns the retrieved data.
#
# Example usage: When you need to fetch user data from a PostgreSQL database to feed into an AI model or process.

class DatabaseQueryFetchAction < Sublayer::Actions::Base
  def initialize(host:, dbname:, user:, password:, query:)
    @connection_params = {
      host: host,
      dbname: dbname,
      user: user,
      password: password
    }
    @query = query
  end

  def call
    begin
      connection = PG.connect(@connection_params)
      result = connection.exec(@query)
      Sublayer.configuration.logger.log(:info, "Query executed successfully: #{@query}")
      result.values
    rescue PG::Error => e
      error_message = "Error executing database query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      connection&.close
    end
  end
end
