# Description: Sublayer::Action responsible for executing a SQL query against a specified database and returning the results.
# This action facilitates integration with existing datasets for dynamic information retrieval.
#
# It is initialized with a database_url, query, and optional parameters for query execution.
# It returns the results of the query execution.
#
# Example usage: When you want to dynamically retrieve data from a database for processing in an LLM.

require 'pg'

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(database_url:, query:, params: {})
    @database_url = database_url
    @query = query
    @params = params
  end

  def call
    begin
      connection = PG.connect(@database_url)
      result = connection.exec_params(@query, @params.values)
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
    result.map { |row| row }
  end
end
