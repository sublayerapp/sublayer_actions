# Description: Sublayer::Action responsible for querying a database based on specified parameters.
# It returns the query result as a JSON array.

# Example usage: When you want to fetch data from a database to use in a Sublayer::Generator

require 'pg'
require 'mysql2'
require 'json'

class DatabaseQueryAction < Sublayer::Actions::Base
  def initialize(db_type:, host:, port:, database:, user:, password:, query:, query_params: [])
    @db_type = db_type.downcase
    @host = host
    @port = port
    @database = database
    @user = user
    @password = password
    @query = query
    @query_params = query_params

    @client = create_db_client
  end

  def call
    begin
      results = @client.query(@query, @query_params)
      results.to_a.to_json
    rescue => e
      error_message = "Error querying database: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      @client.close if @client
    end
  end

  private

  def create_db_client
    case @db_type
    when 'postgresql'
      PG.connect(host: @host, port: @port, dbname: @database, user: @user, password: @password)
    when 'mysql'
      Mysql2::Client.new(host: @host, port: @port, database: @database, username: @user, password: @password)
    else
      raise StandardError, "Unsupported database type: #{@db_type}"
    end
  end
end