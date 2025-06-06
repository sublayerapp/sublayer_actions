require 'pg' # for PostgreSQL
require 'mysql2' # for MySQL

# Description: Sublayer::Action responsible for executing SQL queries on a specified database (e.g., MySQL, PostgreSQL)
# and returning the results. This action is useful for dynamic data retrieval and integration into workflows.
#
# Example usage: When you want to retrieve data dynamically from a database to be used in an AI-driven process

class DatabaseQueryExecuteAction < Sublayer::Actions::Base
  def initialize(db_type:, db_params:, query:)
    @db_type = db_type
    @db_params = db_params
    @query = query
  end

  def call
    begin
      results = execute_query
      Sublayer.configuration.logger.log(:info, "Query executed successfully on #{@db_type} database")
      results
    rescue StandardError => e
      error_message = "Error executing query on #{@db_type} database: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def execute_query
    case @db_type
    when 'postgresql'
      execute_postgresql_query
    when 'mysql'
      execute_mysql_query
    else
      raise ArgumentError, "Unsupported database type: #{@db_type}"
    end
  end

  def execute_postgresql_query
    conn = PG.connect(@db_params)
    begin
      result = conn.exec(@query)
      result.to_a
    ensure
      conn.close
    end
  rescue PG::Error => e
    raise e
  end

  def execute_mysql_query
    client = Mysql2::Client.new(@db_params)
    begin
      result = client.query(@query)
      result.to_a
    ensure
      client.close
    end
  rescue Mysql2::Error => e
    raise e
  end
end