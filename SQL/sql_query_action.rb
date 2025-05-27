require 'sqlite3'

# Description: Sublayer::Action responsible for querying a SQL database and returning the results.
#
# It is initialized with a database connection string and a SQL query.  The action connects to the database,
# executes the query, and returns the result set as an array of hashes.
#
# Example usage: When you want to retrieve structured data from a database for use in a prompt.
#
# Database connection strings are dependent on the type of database.  This example uses SQLite.
#   For other database types, the appropriate gem and connection string format must be used.
# Example:
#   db_string = 'sqlite3:path/to/your/database.db'
#   query = 'SELECT * FROM your_table WHERE condition = something;'
#

class SqlQueryAction < Sublayer::Actions::Base
  def initialize(db_string:, query:)
    @db_string = db_string
    @query = query
  end

  def call
    begin
      uri = URI.parse(@db_string)
      db_type = uri.scheme

      case db_type
      when 'sqlite3'
        db_path = uri.path
        db = SQLite3::Database.new(db_path)
      else
        raise "Unsupported database type: #{db_type}"
      end

      results = query_database(db)
      Sublayer.configuration.logger.log(:info, "Successfully executed SQL query: #{@query}")
      results
    rescue SQLite3::Exception => e
      error_message = "Database error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error executing SQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    ensure
      db&.close if db # Ensure the database connection is closed
    end
  end

  private

  def query_database(db)
    statement = db.prepare @query
    result_set = statement.execute

    column_names = statement.columns
    results = []

    result_set.each do |row|
      results << Hash[column_names.zip(row)]
    end

    results
  end
end