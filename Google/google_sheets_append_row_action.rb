require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for appending a row of data to a Google Sheets spreadsheet.
# This action allows for easy integration with Google Sheets, enabling data logging, storage of generated data,
# or updating trackers in AI workflows.
#
# Requires: 'google-api-client' gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# It is initialized with a spreadsheet_id, sheet_name, and values to append.
# It returns the updated range in A1 notation that now contains the appended data.
#
# Example usage: When you want to log results, store AI-generated data, or update trackers in a Google Sheets spreadsheet.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, sheet_name:, values:)
    @spreadsheet_id = spreadsheet_id
    @sheet_name = sheet_name
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_APPLICATION_CREDENTIALS']),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )
  end

  def call
    begin
      range = "#{@sheet_name}!A:A"
      value_range = Google::Apis::SheetsV4::ValueRange.new(values: [@values])
      result = @service.append_spreadsheet_value(
        @spreadsheet_id,
        range,
        value_range,
        value_input_option: 'USER_ENTERED'
      )
      Sublayer.configuration.logger.log(:info, "Successfully appended row to Google Sheets: #{result.updates.updated_range}")
      result.updates.updated_range
    rescue Google::Apis::Error => e
      error_message = "Error appending row to Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
