require 'sequel'
require 'json'

# Description: Sublayer::Action responsible for querying a database and returning the results as JSON.
# This action supports various database types, including PostgreSQL, MySQL, and SQLite.
#
# It is initialized with a database URL and a SQL query.
# It returns the query results as a JSON string.
#
# Example usage: When you want to retrieve data from a database to use in prompts or update database records based on AI-generated insights.

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(database_url:, sql_query:)
    @database_url = database_url
    @sql_query = sql_query
  end

  def call
    begin
      db = Sequel.connect(@database_url)
      result = db[@sql_query].all
      db.disconnect

      json_result = JSON.generate(result)

      Sublayer.configuration.logger.log(:info, "Successfully executed database query.")
      json_result
    rescue Sequel::Error => e
      error_message = "Database error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue JSON::JSONError => e
      error_message = "JSON serialization error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error querying database: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
