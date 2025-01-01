require 'pg'  # Postgres gem

# Description: Sublayer::Action responsible for inserting data into a specified database table.
# Facilitates data management and storage in workflows that require database interactions.
#
# Example usage: When you need to add records to a database table as part of an AI-driven process.

class DatabaseInsertAction < Sublayer::Actions::Base
  def initialize(db_config:, table_name:, data:)
    @db_config = db_config
    @table_name = table_name
    @data = data
    @connection = PG::Connection.new(@db_config)
  end

  def call
    begin
      insert_data
      Sublayer.configuration.logger.log(:info, "Successfully inserted data into \\#{@table_name}")
    rescue PG::Error => e
      error_message = "Error inserting data into database: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    ensure
      @connection.close if @connection
    end
  end

  private

  def insert_data
    columns = @data.keys.join(", ")
    values = @data.values.map { |value| "'#{value}'" }.join(", ")
    query = "INSERT INTO \\#{@table_name} (\\#{columns}) VALUES (\\#{values})"
    @connection.exec(query)
  end
end
