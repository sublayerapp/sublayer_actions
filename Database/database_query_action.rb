# Description: Sublayer::Action for querying SQL or NoSQL databases, allowing retrieval and processing of data within a Sublayer workflow.
# This action provides a straightforward interface for executing database queries and handling responses.
#
# Example usage: This can be used in workflows where database information needs to be processed or sent to LLMs for analysis.

require 'pg' # For SQL databases like PostgreSQL
require 'mongo' # For NoSQL databases like MongoDB

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(db_type:, connection_params:, query:, options: {})
    @db_type = db_type
    @connection_params = connection_params
    @query = query
    @options = options
  end

  def call
    case @db_type
    when 'sql'
      execute_sql_query
    when 'nosql'
      execute_nosql_query
    else
      raise ArgumentError, "Unsupported database type: #{@db_type}"
    end
  rescue StandardError => e
    error_message = "Error executing database query: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def execute_sql_query
    conn = PG.connect(@connection_params)
    result = conn.exec(@query)
    result.map { |row| row }
  ensure
    conn&.close
  end

  def execute_nosql_query
    client = Mongo::Client.new(@connection_params[:hosts], @options)
    collection = client[@connection_params[:collection]]
    result = collection.find(@query)
    result.to_a
  ensure
    client&.close
  end
end
