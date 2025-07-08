require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for updating specific cells or ranges in Google Sheets.
# This action allows for easy integration with Google Sheets to maintain logs, datasets, or tracking records
# from AI operations and workflows.
#
# Requires:
# - google-api-client gem
# - A Google Cloud project with Sheets API enabled
# - A service account JSON key file with appropriate permissions
#
# It is initialized with:
# - spreadsheet_id: The ID of the Google Sheet (from the URL)
# - range: The A1 notation of the range to update (e.g., 'Sheet1!A1:B2')
# - values: Array of arrays containing the values to write
# - value_input_option: How to interpret the input data (default: 'RAW')
#
# Example usage: When you want to log AI operation results, update tracking spreadsheets,
# or maintain datasets in Google Sheets.
#
# Example:
#   action = GoogleSheetUpdateAction.new(
#     spreadsheet_id: '1234...',
#     range: 'Sheet1!A1:B2',
#     values: [['Data1', 'Data2'], ['Data3', 'Data4']]
#   )
#   action.call

class GoogleSheetUpdateAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:, value_input_option: 'RAW')
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @value_input_option = value_input_option
    @service = initialize_service
  end

  def call
    begin
      update_sheet
      Sublayer.configuration.logger.log(:info, "Successfully updated Google Sheet: #{@spreadsheet_id} range: #{@range}")
    rescue Google::Apis::Error => e
      error_message = "Error updating Google Sheet: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_service
    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_SHEETS_CREDENTIALS']),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )
    service
  end

  def update_sheet
    value_range = Google::Apis::SheetsV4::ValueRange.new(
      range: @range,
      values: @values
    )

    @service.update_spreadsheet_value(
      @spreadsheet_id,
      @range,
      value_range,
      value_input_option: @value_input_option
    )
  end
end