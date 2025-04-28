# Description: Sublayer::Action for interacting with a PostgreSQL database.
# This action allows for executing SQL queries against a PostgreSQL database.
#
# It is initialized with database connection parameters (host, port, database, user, password) and a SQL query.
# It returns the result of the query.
#
# Example usage: When you want to fetch data from a PostgreSQL database for use in an AI-driven workflow.

class PostgreSQLQueryAction < Sublayer::Actions::Base
  def initialize(host:, port:, database:, user:, password:, query:)
    @host = host
    @port = port
    @database = database
    @user = user
    @password = password
    @query = query
  end

  def call
    begin
      conn = PG.connect(host: @host, port: @port, dbname: @database, user: @user, password: @password)
      result = conn.exec(@query)

      Sublayer.configuration.logger.log(:info, "PostgreSQL query executed successfully")

      # Convert the result to a more usable format (array of hashes)
      result.map do |row|
        row.transform_keys(&:to_sym)
      end
    rescue PG::Error => e
      error_message = "Error executing PostgreSQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      conn&.close
    end
  end
end