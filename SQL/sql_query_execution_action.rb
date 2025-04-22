require 'sqlite3'

# Description: Sublayer::Action responsible for executing a SQL query against a database and returning the results.
# This action allows for integration with relational databases.
#
# Requires: 'sqlite3' gem (or the appropriate gem for your database)
# $ gem install sqlite3
# Or add `gem 'sqlite3' to your Gemfile
#
# It is initialized with a database_path and a sql_query.
# It returns an array of hashes, where each hash represents a row in the result set.
#
# Example usage: When you want to query a database to get information for use in an AI-driven workflow.

class SQLQueryExecutionAction < Sublayer::Actions::Base
  def initialize(database_path:, sql_query:)
    @database_path = database_path
    @sql_query = sql_query
  end

  def call
    begin
      db = SQLite3::Database.new @database_path
      results = execute_query(db, @sql_query)
      Sublayer.configuration.logger.log(:info, "Successfully executed SQL query on \#{@database_path}")
      return results
    rescue SQLite3::Exception => e
      error_message = "Error executing SQL query: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      db&.close unless db&.closed?
    end
  end

  private

  def execute_query(db, sql_query)
    rows = db.execute2 sql_query
    columns = rows[0]
    data = rows[1..-1]

    return [] if columns.nil? || data.nil?

    data.map do |row|
      Hash[columns.zip(row)]
    end
  end
end