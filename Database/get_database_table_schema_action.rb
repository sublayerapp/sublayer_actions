require 'pg'
require 'mysql2'

# Description: Sublayer::Action responsible for retrieving the schema of a database table as a string.
# It supports PostgreSQL and MySQL.
#
# It is initialized with a database type (postgres or mysql), connection parameters (host, username, password, database), and the table name.
# It returns a string representation of the table schema.
#
# Example usage: When you need to provide context to a Sublayer::Generator about the structure of a database table.

class GetDatabaseTableSchemaAction < Sublayer::Actions::Base
  def initialize(db_type:, host:, username:, password:, database:, table_name:)
    @db_type = db_type.downcase
    @host = host
    @username = username
    @password = password
    @database = database
    @table_name = table_name
  end

  def call
    case @db_type
    when 'postgres'
      get_postgres_schema
    when 'mysql'
      get_mysql_schema
    else
      error_message = "Unsupported database type: #{@db_type}. Only postgres and mysql are supported."
      Sublayer.configuration.logger.log(:error, error_message)
      raise ArgumentError, error_message
    end
  rescue StandardError => e
    error_message = "Error retrieving database schema: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def get_postgres_schema
    conn = PG.connect(host: @host, user: @username, password: @password, dbname: @database)
    result = conn.exec("SELECT column_name, data_type, is_nullable FROM information_schema.columns WHERE table_name = '#{@table_name}'")

    schema_string = "Table: #{@table_name}\n"
    result.each do |row|
      schema_string += "Column: #{row['column_name']}, Type: #{row['data_type']}, Nullable: #{row['is_nullable']}\n"
    end

    conn.close
    schema_string
  end

  def get_mysql_schema
    client = Mysql2::Client.new(host: @host, username: @username, password: @password, database: @database)
    result = client.query("DESCRIBE `#{@table_name}`")

    schema_string = "Table: #{@table_name}\n"
    result.each do |row|
      schema_string += "Column: #{row['Field']}, Type: #{row['Type']}, Nullable: #{row['Null']}, Key: #{row['Key']}, Default: #{row['Default']}, Extra: #{row['Extra']}\n"
    end

    client.close
    schema_string
  end
end