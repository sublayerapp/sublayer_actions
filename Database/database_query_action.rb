require 'pg'

# Description: Sublayer::Action responsible for executing SQL queries on a specified PostgreSQL database.
# This action allows integration with databases, enabling retrieval or update of information.
#
# It is initialized with db_name, user, password, host, and query.
# It returns the result of the executed query.
#
# Example usage: When you want to retrieve or update information in a PostgreSQL database using an AI-generated SQL query.

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(db_name:, user:, password:, host:, query:)
    @db_name = db_name
    @user = user
    @password = password
    @host = host
    @query = query
  end

  def call
    begin
      connection = connect_to_database
      result = execute_query(connection)
      result
    rescue PG::Error => e
      error_message = "Error executing SQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      connection.close if connection
    end
  end

  private

  def connect_to_database
    PG.connect(dbname: @db_name, user: @user, password: @password, host: @host)
  end

  def execute_query(connection)
    connection.exec(@query)
  end
end
