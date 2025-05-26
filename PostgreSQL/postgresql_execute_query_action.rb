require 'pg'
require 'json'

# Description: Sublayer::Action responsible for executing a SQL query against a PostgreSQL database.
# It allows specifying the connection string and the SQL query to execute. 
# Returns the results as a JSON array.
# Useful for agents that need to interact with relational databases.

class PostgresqlExecuteQueryAction < Sublayer::Actions::Base
  def initialize(connection_string:, sql_query:)
    @connection_string = connection_string
    @sql_query = sql_query
  end

  def call
    begin
      conn = PG.connect(@connection_string)
      res = conn.exec(@sql_query)

      result_array = []
      res.each do |row|
        result_array << row
      end

      conn.close

      Sublayer.configuration.logger.log(:info, "Successfully executed SQL query")
      result_array.to_json
    rescue PG::Error => e
      error_message = "Error executing SQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error connecting to PostgreSQL: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end