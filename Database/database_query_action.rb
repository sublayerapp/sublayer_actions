# Description: Sublayer::Action responsible for querying a database and returning the results as a JSON object.
#
# This action allows for easy data extraction from a database within a Sublayer workflow,
# enabling the use of database information in prompts or for further processing.
#
# It is initialized with a database connection string and a SQL query.
# On successful execution, it returns the query results as a JSON object.
#
# Example usage: When you want to use data from a database to augment a prompt for an LLM.

require 'sqlite3'
require 'json'

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(db_path:, query:)
    @db_path = db_path
    @query = query
  end

  def call
    begin
      results = query_database
      Sublayer.configuration.logger.log(:info, "Successfully queried database at \#{@db_path}")
      results
    rescue SQLite3::Exception => e
      error_message = "Error querying database: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue JSON::JSONError => e
      error_message = "Error converting results to JSON: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def query_database
    db = SQLite3::Database.new @db_path
    db.results_as_hash = true
    statement = db.prepare @query
    results = statement.execute

    # Convert results to a JSON string
    json_results = results.to_a.to_json
    statement.close
    db.close
    
    json_results
  end
end