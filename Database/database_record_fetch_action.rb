require 'sequel'

# Description: Sublayer::Action responsible for fetching records from a SQL database table.
# This action allows for dynamic data retrieval using customizable query parameters.
#
# Example usage: When an AI workflow needs to fetch record data for analysis or further processing.

class DatabaseRecordFetchAction < Sublayer::Actions::Base
  def initialize(database_url:, table_name:, query_params: {})
    @database_url = database_url
    @table_name = table_name
    @query_params = query_params
    @db = Sequel.connect(@database_url)
  end

  def call
    fetch_records
  rescue Sequel::DatabaseError => e
    error_message = "Database error during record fetch: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error fetching records: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def fetch_records
    dataset = @db[@table_name.to_sym]
    @query_params.each do |key, value|
      dataset = dataset.where(key => value)
    end
    records = dataset.all
    Sublayer.configuration.logger.log(:info, "Successfully fetched #{records.size} records from #{@table_name}")
    records
  end
end
