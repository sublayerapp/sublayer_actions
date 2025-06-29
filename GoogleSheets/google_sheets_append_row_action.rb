require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for appending new rows of data to an existing Google Sheet.
# This action supports batch updates and adheres to data validation rules set within the sheet.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# It is initialized with spreadsheet_id, range, and values (an array of arrays, each representing a row).
#
# Example usage: When you want to programatically add data collected from various sources to a specific Google Sheet for tracking or reporting.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values: [], credentials: nil)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @credentials = credentials || Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_SERVICE_ACCOUNT_JSON_PATH']),
      scope: ['https://www.googleapis.com/auth/spreadsheets']
    )
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = @credentials
  end

  def call
    append_rows
  rescue Google::Apis::Error => e
    error_message = "Error appending rows to Google Sheet: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "An unexpected error occurred: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def append_rows
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: @range, values: @values)
    @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'RAW')
    Sublayer.configuration.logger.log(:info, "Rows appended successfully to Google Sheet #{@spreadsheet_id}")
  end
end