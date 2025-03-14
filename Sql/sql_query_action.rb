# Description: Sublayer::Action responsible for querying a SQL database and returning the results.
#
# It is initialized with a database connection string and a SQL query.
# It returns an array of hashes, where each hash represents a row in the result set.
#
# Example usage: When you want to provide context to a Sublayer::Generator by fetching data from a database,
# or when you have an AI agent that needs to analyze data stored in a SQL database.

require 'sequel'

class Sql\SqlQueryAction < Sublayer::Actions::Base
  def initialize(db_connection_string:, sql_query:)
    @db_connection_string = db_connection_string
    @sql_query = sql_query
  end

  def call
    begin
      db = Sequel.connect(@db_connection_string)
      result = db[@sql_query].to_a
      db.disconnect

      Sublayer.configuration.logger.log(:info, "Successfully executed SQL query")
      result
    rescue Sequel::Error => e
      error_message = "Error executing SQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error connecting to the database: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end