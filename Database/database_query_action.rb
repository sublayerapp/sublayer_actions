# Description: Sublayer::Action responsible for querying a SQL database.
# This action allows integration with SQL databases to retrieve data based on provided SQL query strings,
# facilitating retrieval of structured data for LLM processing or other workflows.
#
# Example usage: When you want to fetch data from a SQL database to use within an AI processing pipeline.

require 'pg' # Assume we're using PostgreSQL. Ensure to add any required database gem.

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(connection_params:, query:)
    @connection_params = connection_params
    @query = query
  end

  def call
    begin
      result = execute_query
      Sublayer.configuration.logger.log(:info, "Query executed successfully. Returned #{result.ntuples} rows.")
      format_result(result)
    rescue PG::Error => e
      error_message = "Error executing SQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      @connection.close if @connection
    end
  end

  private

  def execute_query
    @connection = PG.connect(@connection_params)
    @connection.exec(@query)
  end

  def format_result(result)
    result.map { |row| row } # Convert PG::Result to array of hashes (or any other format needed)
  end
end
