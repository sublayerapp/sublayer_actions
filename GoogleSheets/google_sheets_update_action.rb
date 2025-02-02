require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for updating a specific range in a Google Sheets spreadsheet.
# This action allows for easy integration with Google Sheets, enabling data logging, report generation,
# or updating tracking sheets based on AI analysis or other Sublayer actions.
#
# It is initialized with the spreadsheet_id, range, and values to update.
# It returns the UpdateValuesResponse object from the Google Sheets API to confirm the update was successful.
#
# Example usage: When you want to log results from an AI analysis into a Google Sheets spreadsheet.

class GoogleSheetsUpdateAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_APPLICATION_CREDENTIALS']),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )
  end

  def call
    begin
      request_body = Google::Apis::SheetsV4::ValueRange.new(values: @values)
      response = @service.update_spreadsheet_value(
        @spreadsheet_id,
        @range,
        request_body,
        value_input_option: 'USER_ENTERED'
      )
      Sublayer.configuration.logger.log(:info, "Successfully updated Google Sheets: #{response.updated_cells} cells updated")
      response
    rescue Google::Apis::Error => e
      error_message = "Error updating Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
