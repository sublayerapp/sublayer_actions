require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for appending a row of data to a Google Sheets document.
# This action allows for easy logging of results, maintaining dynamic reports, or updating tracking sheets.
#
# It is initialized with a spreadsheet_id, range, and values to be added.
# It returns a confirmation message upon successful execution.
#
# Example usage: When you want to log activity from an AI process to a Google Sheets document.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = "Sublayer"
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/spreadsheets"])
  end

  def call
    append_row
  rescue Google::Apis::Error => e
    error_message = "Google API error during row append: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error appending row in Google Sheets: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def append_row
    value_range = Google::Apis::SheetsV4::ValueRange.new(values: [@values])
    @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range, value_input_option: 'USER_ENTERED')
    Sublayer.configuration.logger.log(:info, "Row appended successfully to Google Sheets document")
    "Row appended successfully"
  end
end
