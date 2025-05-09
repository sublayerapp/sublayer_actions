require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for appending a row of data to a Google Sheets spreadsheet.
# This action allows for easy integration with Google Sheets, enabling automatic updates of spreadsheets
# with AI-generated data, logging results, or updating tracking information.
#
# It is initialized with a spreadsheet_id, sheet_name, and row_data.
# It returns the updated range where the data was appended.
#
# Example usage: When you want to log AI-generated results or update a tracking sheet automatically.
#
# Note: Requires the 'google-api-client' gem and appropriate Google Cloud credentials.
# Make sure to set up a Google Cloud project and enable the Google Sheets API.
# Store the credentials JSON file path in the GOOGLE_APPLICATION_CREDENTIALS environment variable.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, sheet_name:, row_data:)
    @spreadsheet_id = spreadsheet_id
    @sheet_name = sheet_name
    @row_data = row_data
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = Google::Auth.get_application_default(['https://www.googleapis.com/auth/spreadsheets'])
  end

  def call
    begin
      range = "#{@sheet_name}!A:A"
      value_range = Google::Apis::SheetsV4::ValueRange.new(values: [@row_data])
      
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
