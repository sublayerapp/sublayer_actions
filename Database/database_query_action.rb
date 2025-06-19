# Description: Sublayer::Action to execute a SQL query against a database and return the results.
#
# It is initialized with a database connection configuration, the query to execute, and optionally, a logger.
# It returns the results of the query as an array of hashes.
#
# Example usage: When you want to extract specific information from databases for analysis or decision-making in an AI agent.

require 'pg'
require 'logger'

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(db_config:, query:, logger: nil)
    @db_config = db_config
    @query = query
    @logger = logger || Logger.new(STDOUT)
  end

  def call
    begin
      connection = PG.connect(@db_config)
      result = connection.exec(@query)
      
      # Convert PG::Result to array of hashes
      results = result.map do |row|
        row.to_h
      end

      @logger.info("Successfully executed query: #{@query}")
      results
    rescue PG::Error => e
      @logger.error("Error executing SQL query: #{e.message}")
      raise StandardError, "Error executing SQL query: #{e.message}"
    ensure
      connection&.close if connection
    end
  end
end