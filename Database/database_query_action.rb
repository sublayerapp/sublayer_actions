require 'sequel'

# Description: Sublayer::Action responsible for executing SQL queries on various databases.
# This action provides a flexible interface for querying SQL databases, allowing AI workflows
# to retrieve or update data from different database systems.
#
# Requires: 'sequel' gem
# $ gem install sequel
# You may also need to install the appropriate database adapter gem (e.g., 'pg' for PostgreSQL)
#
# It is initialized with connection details, query, and optional query parameters.
# It returns the result of the query execution.
#
# Example usage: When you want to retrieve or manipulate data in a SQL database as part of an AI-driven workflow.

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(connection_string:, query:, params: {})
    @connection_string = connection_string
    @query = query
    @params = params
  end

  def call
    begin
      db = Sequel.connect(@connection_string)
      result = db[@query, @params].all
      Sublayer.configuration.logger.log(:info, "Successfully executed database query")
      result
    rescue Sequel::Error => e
      error_message = "Error executing database query: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      db.disconnect if db
    end
  end
end
