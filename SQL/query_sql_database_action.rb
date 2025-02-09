require 'pg'

# Description: Sublayer::Action responsible for querying a SQL database.
# This action allows AI agents to access information from relational databases,
# which is a common requirement for data processing and integration tasks.
#
# It is initialized with a database URL, query, and optional parameters.
# It returns the result of the SQL query as an array of hashes.
#
# Example usage: When you want to fetch data from a SQL database to use in an AI-driven workflow.

class QuerySqlDatabaseAction < Sublayer::Actions::Base
  def initialize(database_url:, query:, params: [])
    @database_url = database_url
    @query = query
    @params = params
  end

  def call
    begin
      conn = PG.connect(@database_url)
      results = conn.exec_params(@query, @params)

      Sublayer.configuration.logger.log(:info, "Successfully executed SQL query")

      results.map do |row|
        row.transform_keys(&:to_sym) # Convert string keys to symbols 
      end
    rescue PG::Error => e
      error_message = "Error querying SQL database: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      conn&.close
    end
  end
end