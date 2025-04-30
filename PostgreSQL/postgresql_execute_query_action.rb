# Description: Sublayer::Action for interacting with a PostgreSQL database.
# This action allows execution of SQL queries, insertion, updates, and deletions,
# enabling Sublayer to interact with persistent data.
#
# It uses the `pg` gem. Make sure to add `gem 'pg'` to your Gemfile and `require 'pg'`
# at the top of any file that uses this action.
#
# Example usage: When you need to read or write data to a PostgreSQL database
# within a Sublayer workflow.

require 'pg'

class PostgresqlExecuteQueryAction < Sublayer::Actions::Base
  def initialize(query:, database_url:)
    @query = query
    @database_url = database_url || ENV['DATABASE_URL']
  end

  def call
    begin
      conn = PG.connect(@database_url)
      result = conn.exec(@query)

      Sublayer.configuration.logger.log(:info, "PostgreSQL query executed successfully: #{@query}")

      # Convert the result to an array of hashes
      result.map do |row|
        row.to_h
      end
    rescue PG::Error => e
      error_message = "Error executing PostgreSQL query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      conn&.close
    end
  end
end