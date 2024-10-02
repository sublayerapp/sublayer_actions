require 'mysql2'
require 'pg'
require 'sqlite3'

# Description: Sublayer::Action for executing SQL queries on various database types (MySQL, PostgreSQL, SQLite).
# This action is useful for AI applications that need to interact with databases for data retrieval or manipulation.
#
# It is initialized with database connection parameters and a SQL query, and returns the query results.
#
# Example usage: When you need to fetch or manipulate data from a database as part of an AI workflow,
# you can use this action to execute the necessary SQL queries.

class SQLDatabaseQueryAction < Sublayer::Actions::Base
  def initialize(db_type:, query:, host: nil, port: nil, database:, username: nil, password: nil)
    @db_type = db_type.to_sym
    @query = query
    @host = host
    @port = port
    @database = database
    @username = username
    @password = password
  end

  def call
    client = connect_to_database
    execute_query(client)
  rescue StandardError => e
    log_error(e)
    raise e
  ensure
    close_connection(client) if client
  end

  private

  def connect_to_database
    case @db_type
    when :mysql
      Mysql2::Client.new(host: @host, username: @username, password: @password, database: @database, port: @port)
    when :postgresql
      PG.connect(host: @host, user: @username, password: @password, dbname: @database, port: @port)
    when :sqlite
      SQLite3::Database.new(@database)
    else
      raise ArgumentError, "Unsupported database type: #{@db_type}"
    end
  end

  def execute_query(client)
    case @db_type
    when :mysql
      client.query(@query)
    when :postgresql
      client.exec(@query)
    when :sqlite
      client.execute(@query)
    end
  end

  def close_connection(client)
    client.close
  rescue StandardError => e
    log_error(e, "Error closing database connection")
  end

  def log_error(error, message = "Error executing SQL query")
    Sublayer.logger.error("#{message}: #{error.message}")
    Sublayer.logger.error(error.backtrace.join("\n"))
  end
end