# Description: Sublayer::Action responsible for executing a SQL query against a database.
#
# This action allows for querying a database and returning the result set.
#
# Requires: 'pg' gem for PostgreSQL or 'mysql2' gem for MySQL.  Make sure the appropriate gem is installed.
# $ gem install pg  or  $ gem install mysql2
#
# It is initialized with a database_url and a sql_query.
# It returns the result set from the query.
#
# Example usage: When you need to query a database as part of an AI-driven process.

require 'uri'
require 'pg'
require 'mysql2'

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(database_url:, sql_query:)
    @database_url = database_url
    @sql_query = sql_query
  end

  def call
    begin
      uri = URI.parse(@database_url)
      db_type = uri.scheme

      case db_type
      when 'postgres'
        result = execute_postgres_query(uri)
      when 'mysql', 'mysql2'
        result = execute_mysql_query(uri)
      else
        raise "Unsupported database type: #{db_type}"
      end

      Sublayer.configuration.logger.log(:info, "Successfully executed SQL query.")
      result
    rescue StandardError => e
      error_message = "Error executing SQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def execute_postgres_query(uri)
    connection_params = {
      host: uri.host,
      port: uri.port,
      dbname: uri.path[1..-1],
      user: uri.user,
      password: uri.password,
    }

    PG.connect(connection_params) do |conn|
      result = conn.exec(@sql_query)
      result.to_a # Convert PG::Result to array of hashes
    end
  end

  def execute_mysql_query(uri)
    client = Mysql2::Client.new(
      host: uri.host,
      port: uri.port,
      username: uri.user,
      password: uri.password,
      database: uri.path[1..-1]
    )

    result = client.query(@sql_query)
    result.to_a # Convert Mysql2::Result to array of hashes
  ensure
    client&.close # Ensure the connection is closed
  end
end