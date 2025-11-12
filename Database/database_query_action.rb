require 'pg'

# Description: Sublayer::Action responsible for executing a SQL query against a database and returning the result set.
#
# It is initialized with a database connection string, query string, and expected result format.
# The action uses the 'pg' gem to connect to PostgreSQL databases.
#
# Example usage: When you want to retrieve data from a database for use in a Sublayer::Generator prompt or to drive other actions.

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(connection_string:, query_string:)
    @connection_string = connection_string
    @query_string = query_string
  end

  def call
    begin
      connection = PG.connect(@connection_string)
      result = connection.exec(@query_string)

      # Convert PG::Result to a more easily serializable format (array of hashes)
      result_set = result.map do |row|
        row.each_with_object({}) do |(key, value), hash|
          hash[key.to_sym] = value
        end
      end

      Sublayer.configuration.logger.log(:info, "Successfully executed database query.")
      result_set
    rescue PG::Error => e
      error_message = "Error executing database query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      connection&.close if connection
    end
  end
end
