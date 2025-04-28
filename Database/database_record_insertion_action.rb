require 'mysql2'
require 'pg'
require 'mongo'

# Description: Sublayer::Action responsible for inserting a record into different types of databases such as MySQL, PostgreSQL, and MongoDB.
# This action facilitates integration with data-driven applications, allowing easy insertion of data into various database systems.
#
# It is initialized with database configurations and the record to be inserted.
# It includes error handling and logging for seamless integration.
#
# Example usage: When you want to insert AI-generated data into a database for further use or analysis.

class DatabaseRecordInsertionAction < Sublayer::Actions::Base
  def initialize(db_type:, db_config:, collection_or_table:, record:)
    @db_type = db_type.downcase
    @db_config = db_config
    @collection_or_table = collection_or_table
    @record = record
  end

  def call
    case @db_type
    when 'mysql'
      insert_into_mysql
    when 'postgresql'
      insert_into_postgresql
    when 'mongodb'
      insert_into_mongodb
    else
      raise ArgumentError, "Unsupported database type: #{@db_type}"
    end
  rescue StandardError => e
    Sublayer.configuration.logger.log(:error, "Error inserting record: #{e.message}")
    raise e
  end

  private

  def insert_into_mysql
    client = Mysql2::Client.new(@db_config)
    keys = @record.keys.join(', ')
    values = @record.values.map { |v| client.escape(v.to_s) }.join(', ')
    query = "INSERT INTO #{@collection_or_table} (#{keys}) VALUES (#{values})"
    client.query(query)
    Sublayer.configuration.logger.log(:info, "Record inserted successfully into MySQL table #{@collection_or_table}")
  ensure
    client.close if client
  end

  def insert_into_postgresql
    conn = PG.connect(@db_config)
    keys = @record.keys.join(', ')
    values = @record.values.map { |v| "'#{PG::Connection.escape_string(v.to_s)}'" }.join(', ')
    query = "INSERT INTO #{@collection_or_table} (#{keys}) VALUES (#{values})"
    conn.exec(query)
    Sublayer.configuration.logger.log(:info, "Record inserted successfully into PostgreSQL table #{@collection_or_table}")
  ensure
    conn.close if conn
  end

  def insert_into_mongodb
    client = Mongo::Client.new(["#{@db_config[:host]}:#{@db_config[:port]}"], database: @db_config[:database])
    collection = client[@collection_or_table]
    result = collection.insert_one(@record)
    if result.n == 1
      Sublayer.configuration.logger.log(:info, "Record inserted successfully into MongoDB collection #{@collection_or_table}")
    else
      raise StandardError, "Failed to insert record into MongoDB"
    end
  ensure
    client.close if client
  end
end
