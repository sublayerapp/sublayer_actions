require 'pg'
require 'mysql2'

# Description: Sublayer::Action responsible for executing SQL queries on a connected database.
# Supports PostgreSQL and MySQL databases, and returns the query results for further processing in Sublayer workflows.
#
# It is initialized with connection parameters and a SQL query string.
# It returns the results of the SQL query.
#
# Example usage: When you need to pull data from a database as part of a Sublayer workflow.

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(db_type:, host:, dbname:, user:, password:, query:)
    @db_type = db_type.downcase
    @host = host
    @dbname = dbname
    @user = user
    @password = password
    @query = query
  end

  def call
    begin
      case @db_type
      when 'postgresql'
        results = execute_postgresql_query
      when 'mysql'
        results = execute_mysql_query
      else
        raise ArgumentError, "Unsupported database type: #{@db_type}"
      end

      Sublayer.configuration.logger.log(:info, "Query executed successfully on #{@db_type} database")
      results
    rescue StandardError => e
      error_message = "Error executing database query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def execute_postgresql_query
    conn = PG.connect(host: @host, dbname: @dbname, user: @user, password: @password)
    result = conn.exec(@query)
    conn.close
    result.values
  end

  def execute_mysql_query
    client = Mysql2::Client.new(host: @host, database: @dbname, username: @user, password: @password)
    result = client.query(@query)
    client.close
    result.to_a
  end
end
