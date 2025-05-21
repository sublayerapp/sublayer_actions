require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action for appending new rows to a specific Google Sheet.
# This action is perfect for ongoing data collection or maintaining logs for generators or actions needing structured data.
#
# It is initialized with the spreadsheet_id, range, and values to append.
# It returns the result of the append operation as confirmation.
#
# Example usage: When you want to log AI-generated insights into a Google Sheet or maintain structured data for analysis.

class GoogleSheetsDataAppendAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = init_service
  end

  def call
    begin
      result = append_data
      Sublayer.configuration.logger.log(:info, "Data appended successfully to Google Sheet: ")
      result
    rescue Google::Apis::ServerError => e
      error_message = "Google API server error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ClientError => e
      error_message = "Google API client error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error appending data to Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def init_service
    scopes = ["https://www.googleapis.com/auth/spreadsheets"]
    Google::Apis::SheetsV4::SheetsService.new.tap do |service|
      service.client_options.application_name = "Sublayer Actions"
      service.authorization = Google::Auth.get_application_default(scopes)
    end
  end

  def append_data
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(
      range: @range,
      values: @values
    )

    @service.append_spreadsheet_value(
      @spreadsheet_id,
      @range,
      value_range_object,
      value_input_option: 'USER_ENTERED'
    )
  end
end