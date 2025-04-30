require 'googleauth'
require 'google/apis/sheets_v4'

# Description: Sublayer::Action responsible for appending data to a specified Google Sheets document.
# This action is useful for logging AI-generated insights or appending structured data for reporting.
#
# It is initialized with a spreadsheet_id, range, and values to append.
#
# Example usage: When you want to log AI-generated insights into a Google Sheet for tracking purposes.

class GoogleSheetsDataAppendAction < Sublayer::Actions::Base
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = 'Sublayer'
    @service.authorization = authorize
  end

  def call
    append_data
  rescue Google::Apis::Error => e
    error_message = "Error appending data to Google Sheets: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Unexpected error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def authorize
    Google::Auth.get_application_default([SCOPE])
  end

  def append_data
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: @range, values: @values)
    response = @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'RAW')
    Sublayer.configuration.logger.log(:info, "Successfully appended data to Google Sheets")
    response
  end
end
