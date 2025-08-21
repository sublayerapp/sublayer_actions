require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for appending a new row of data to a specified Google Sheet.
# This action communicates with the Google Sheets API to add data efficiently.
#
# It is initialized with a spreadsheet_id and row_data, and confirms success by returning the updated row ID.
#
# Example usage: When you want to log AI-generated insights or results to a Google Sheet for further analysis or reporting.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, row_data:)
    @spreadsheet_id = spreadsheet_id
    @row_data = row_data
    @service = initialize_google_sheets_service
  end

  def call
    begin
      append_row_to_sheet
    rescue Google::Apis::Error => e
      error_message = "Error appending row to Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def initialize_google_sheets_service
    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/spreadsheets"])
    service
  end

  def append_row_to_sheet
    range = 'Sheet1!A1:Z1'
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: range, values: [@row_data])

    response = @service.append_spreadsheet_value(@spreadsheet_id, range, value_range_object, value_input_option: 'USER_ENTERED')

    appended_row_id = response.updates.updated_range.split('!').last.split(':').first
    Sublayer.configuration.logger.log(:info, "Row appended successfully to Google Sheet with ID: #{appended_row_id}")

    appended_row_id
  end
end