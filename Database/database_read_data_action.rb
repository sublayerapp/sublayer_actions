# Description: Sublayer::Action responsible for reading data from a database.
# It supports multiple database types (e.g., PostgreSQL, MySQL, SQLite) and requires secure configuration.
#
# It is initialized with a database type, connection parameters, and a query.
# It returns an array of results from the database.
#
# Example usage: When you need to retrieve data from a database to use in a Sublayer::Generator for further processing or decision-making.

require 'sequel'

class DatabaseReadDataAction < Sublayer::Actions::Base
  def initialize(database_type:, connection_params:, query:)
    @database_type = database_type
    @connection_params = connection_params
    @query = query
    @db = nil
  end

  def call
    begin
      connect_to_database
      results = execute_query
      Sublayer.configuration.logger.log(:info, "Successfully read data from database.")
      results
    rescue Sequel::Error => e
      error_message = "Database error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error reading data from database: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    ensure
      disconnect_from_database if @db
    end
  end

  private

  def connect_to_database
    connection_string = build_connection_string
    @db = Sequel.connect(connection_string)
    Sublayer.configuration.logger.log(:info, "Successfully connected to database.")
  end

  def build_connection_string
    case @database_type.to_sym
    when :postgres
      "postgres://#{@connection_params[:user]}:#{@connection_params[:password]}@#{@connection_params[:host]}:#{@connection_params[:port]}/#{@connection_params[:database]}"
    when :mysql
      "mysql2://#{@connection_params[:user]}:#{@connection_params[:password]}@#{@connection_params[:host]}:#{@connection_params[:port]}/#{@connection_params[:database]}"
    when :sqlite
      "sqlite://#{@connection_params[:database_path]}"
    else
      raise ArgumentError, "Unsupported database type: #{@database_type}"
    end
  end

  def execute_query
    @db[@query].all
  end

  def disconnect_from_database
    @db.disconnect
    Sublayer.configuration.logger.log(:info, "Successfully disconnected from database.")
  end
end