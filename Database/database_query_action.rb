require 'pg'
require 'mysql2'
require 'json'

# Description: Sublayer::Action responsible for executing a SQL query against a database and returning the result set as a JSON array.
#
# This action supports PostgreSQL and MySQL databases.
#
# It is initialized with a database type, connection string, and SQL query.
# It returns the result set as a JSON array.
#
# Example usage: When you want to retrieve data from a database for use in a Sublayer::Generator.

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(database_type:, connection_string:, sql_query:)
    @database_type = database_type.downcase
    @connection_string = connection_string
    @sql_query = sql_query
  end

  def call
    begin
      results = execute_query
      Sublayer.configuration.logger.log(:info, "Successfully executed SQL query")
      results
    rescue StandardError => e
      error_message = "Error executing SQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def execute_query
    case @database_type
    when 'postgresql'
      execute_postgresql_query
    when 'mysql'
      execute_mysql_query
    else
      raise StandardError, "Unsupported database type: #{@database_type}. Supported types are: postgresql, mysql"
    end
  end

  def execute_postgresql_query
    uri = URI.parse(@connection_string)
    conn = PG.connect(uri.hostname, uri.port, nil, nil, uri.path[1..-1], uri.user, uri.password)

    result = conn.exec(@sql_query)
    json_result = result.map { |row| row }
    conn.close
    json_result.to_json
  rescue PG::Error => e
    Sublayer.configuration.logger.log(:error, "PostgreSQL error: #{e.message}")
    raise StandardError, "PostgreSQL error: #{e.message}"
  end

  def execute_mysql_query
    uri = URI.parse(@connection_string)
    client = Mysql2::Client.new(
      host: uri.hostname,
      port: uri.port,
      username: uri.user,
      password: uri.password,
      database: uri.path[1..-1]
    )

    result = client.query(@sql_query)
    json_result = result.map { |row| row }
    client.close
    json_result.to_json
  rescue Mysql2::Error => e
    Sublayer.configuration.logger.log(:error, "MySQL error: #{e.message}")
    raise StandardError, "MySQL error: #{e.message}"
  end
end