require 'pg'

# Description: Sublayer::Action responsible for inserting a new record into a specified database table.
# This action is ideal for persisting data outputs from AI models into a structured format.
#
# Requires: `pg` gem
# $ gem install pg
#
# It is initialized with a connection params, table_name, and record_data.
# It performs the insertion operation and returns the result.
#
# Example usage: When you have AI-generated data that needs to be saved into a database table.

class DatabaseRecordInserterAction < Sublayer::Actions::Base
  def initialize(connection_params:, table_name:, record_data: {})
    @connection_params = connection_params
    @table_name = table_name
    @record_data = record_data
  end

  def call
    conn = connect_to_database
    insert_record(conn)
  ensure
    conn&.close
  end

  private

  def connect_to_database
    PG.connect(@connection_params)
  rescue PG::Error => e
    Sublayer.configuration.logger.log(:error, "Error connecting to database: #{e.message}")
    raise StandardError, "Database connection error"
  end

  def insert_record(conn)
    columns = @record_data.keys.join(", ")
    values = @record_data.values.map { |value| conn.escape_literal(value.to_s) }.join(", ")
    query = "INSERT INTO #{@table_name} (#{columns}) VALUES (#{values})"

    conn.exec(query)
    Sublayer.configuration.logger.log(:info, "Record inserted successfully into #{@table_name}")
  rescue PG::Error => e
    Sublayer.configuration.logger.log(:error, "Error inserting record: #{e.message}")
    raise StandardError, "Record insertion error"
  end
end
