require 'sqlite3'
require 'pg'

# Description: Sublayer::Action responsible for executing a SQL query against a specified database.
# Supports both SQLite3 and PostgreSQL.
#
# It is initialized with a database_url (connection string) and a sql_query.
# The database_url should specify the database type (sqlite3 or postgres) and the connection details.
# It returns the result of the SQL query as an array of hashes.
#
# Example usage:
# For SQLite3: database_url: 'sqlite3:path/to/your/database.db', sql_query: 'SELECT * FROM users;'
# For PostgreSQL: database_url: 'postgres://user:password@host:port/database', sql_query: 'SELECT * FROM users;'

class DatabaseExecuteSqlQueryAction < Sublayer::Actions::Base
  def initialize(database_url:, sql_query:)
    @database_url = database_url
    @sql_query = sql_query
    @db_type = determine_db_type
  end

  def call
    begin
      results = execute_query
      Sublayer.configuration.logger.log(:info, "SQL query executed successfully against \#{@database_url}")
      results
    rescue StandardError => e
      error_message = "Error executing SQL query: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def determine_db_type
    if @database_url.start_with?('sqlite3:')
      :sqlite3
    elsif @database_url.start_with?('postgres://')
      :postgres
    else
      raise ArgumentError, "Unsupported database type.  Must start with 'sqlite3:' or 'postgres://'"
    end
  end

  def execute_query
    case @db_type
    when :sqlite3
      execute_sqlite3_query
    when :postgres
      execute_postgres_query
    end
  end

  def execute_sqlite3_query
    db_path = @database_url.split(':').last
    db = SQLite3::Database.new(db_path)
    results = db.execute(@sql_query)
    db.close
    format_results(results)
  end

  def execute_postgres_query
    uri = URI.parse(@database_url)
    conn = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)
    results = conn.exec(@sql_query)
    conn.close
    format_results(results)
  end

  def format_results(results)
    # Handle results differently based on the source
    if results.is_a?(PG::Result)
      # Convert PG::Result to array of hashes
      field_names = results.fields
      results.map do |row|
        Hash[field_names.zip(row)]
      end
    elsif results.is_a?(Array) && results.first.is_a?(Array)
      # SQLite3 returns an array of arrays.  We don't have column names easily available, so for now just returning the data.
      results.map {|row| row}
    else
      [] # Or handle other cases as needed
    end
  end
end