require 'pg'

# Description: Sublayer::Action responsible for executing SQL queries against a PostgreSQL database.
# This action provides a simple interface for database interactions within Sublayer workflows.
#
# Requires: 'pg' gem
# $ gem install pg
# Or add `gem 'pg'` to your Gemfile
#
# It is initialized with a query string and optional connection parameters.
# If connection parameters are not provided, it will use environment variables:
# - POSTGRES_HOST
# - POSTGRES_PORT
# - POSTGRES_DATABASE
# - POSTGRES_USER
# - POSTGRES_PASSWORD
#
# Returns an array of hashes where each hash represents a row from the query results.
#
# Example usage: When you want to retrieve data from a PostgreSQL database to use in an AI workflow,
# or when storing AI-generated insights into a database.

class PostgreSQLQueryAction < Sublayer::Actions::Base
  def initialize(query:, host: nil, port: nil, dbname: nil, user: nil, password: nil)
    @query = query
    @connection_params = {
      host: host || ENV['POSTGRES_HOST'],
      port: port || ENV['POSTGRES_PORT'],
      dbname: dbname || ENV['POSTGRES_DATABASE'],
      user: user || ENV['POSTGRES_USER'],
      password: password || ENV['POSTGRES_PASSWORD']
    }
  end

  def call
    begin
      results = execute_query
      Sublayer.configuration.logger.log(:info, 'PostgreSQL query executed successfully')
      results
    rescue PG::Error => e
      error_message = "PostgreSQL query error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      @connection&.close if @connection
    end
  end

  private

  def execute_query
    @connection = PG.connect(@connection_params)
    result = @connection.exec(@query)
    
    # Convert result to array of hashes
    result.map { |row| row.transform_keys(&:to_sym) }
  end
end