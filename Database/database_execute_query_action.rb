class DatabaseExecuteQueryAction < Sublayer::Actions::Base
  # Description: Sublayer::Action responsible for executing a query against a database.
  # This action allows for integration with databases, enabling data retrieval and manipulation.
  #
  # It is initialized with connection_string, query, and optional parameters.
  # It returns the result of the query execution.
  #
  # Example usage: When you want to fetch or modify data in a database as part of an AI workflow.

  def initialize(connection_string:, query:, parameters: [])
    @connection_string = connection_string
    @query = query
    @parameters = parameters
  end

  def call
    begin
      result = execute_query
      Sublayer.configuration.logger.log(:info, "Database query executed successfully")
      result
    rescue StandardError => e
      error_message = "Error executing database query: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def execute_query
    # Implement database connection and query execution logic here
    # This will depend on the specific database being used
    # Example using PG gem for PostgreSQL:
    # require 'pg'
    # conn = PG.connect(@connection_string)
    # result = conn.exec_params(@query, @parameters)
    # conn.close
    # return result
  end
end