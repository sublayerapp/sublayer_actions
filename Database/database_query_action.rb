# Description: Sublayer::Action responsible for querying a database and returning the results.
#
# This action allows you to pass in a database connection string and query and get structured data back
# for use in Sublayer::Generators or other Sublayer::Actions. It uses the Sequel gem for database interaction.
#
# Requires: sequel gem and a database adapter gem (e.g., pg for PostgreSQL, sqlite3 for SQLite)
# $ gem install sequel pg # Example for PostgreSQL
#
# It is initialized with a database connection string and a query.
# It returns an array of hashes, where each hash represents a row in the result set.
#
# Example usage: When you want to retrieve data from a database to augment a prompt or drive a decision.

require 'sequel'

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(db_connection_string:, query:)
    @db_connection_string = db_connection_string
    @query = query
  end

  def call
    begin
      db = Sequel.connect(@db_connection_string)
      result = db[@query].all
      Sublayer.configuration.logger.log(:info, "Successfully executed database query.")
      result
    rescue Sequel::Error => e
      error_message = "Error querying the database: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error connecting to the database: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    ensure
      db.disconnect if db # Ensure the connection is closed
    end
  end
end