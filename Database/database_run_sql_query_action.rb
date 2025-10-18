require 'sqlite3'
require 'pg'

# Description: Sublayer::Action responsible for running a SQL query against a specified database.
# This action supports both SQLite3 and PostgreSQL databases.
#
# It is initialized with a database connection string, the SQL query to execute, and the database type (sqlite or postgres).
# It returns the result set as an array of hashes, where each hash represents a row.
#
# Example usage: When you need to retrieve data from a database to use in a Sublayer::Generator for generating reports, summaries, etc.

class DatabaseRunSqlQueryAction < Sublayer::Actions::Base
  def initialize(db_type:, connection_string:, sql_query:)
    @db_type = db_type.downcase # Enforce lowercase for db_type
    @connection_string = connection_string
    @sql_query = sql_query
  end

  def call
    begin
      results = execute_query
      Sublayer.configuration.logger.log(:info, "Successfully executed SQL query.")
      results
    rescue StandardError => e
      error_message = "Error executing SQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def execute_query
    case @db_type
    when 'sqlite'
      execute_sqlite_query
    when 'postgres'
      execute_postgres_query
    else
      raise ArgumentError, "Unsupported database type: #{@db_type}. Supported types are 'sqlite' and 'postgres'."
    end
  end

  def execute_sqlite_query
    db = SQLite3::Database.new @connection_string
    db.results_as_hash = true
    statement = db.prepare @sql_query
    result_set = statement.execute
    results = []
    result_set.each { |row| results << row }
    statement.close
    db.close
    results
  end

  def execute_postgres_query
    conn = PG.connect(@connection_string)
    result = conn.exec(@sql_query)
    results = result.map do |row|
      row.each_with_object({}) do |(key, value), hash|
        hash[key.to_sym] = value
      end
    end
    conn.close
    results
  end
end