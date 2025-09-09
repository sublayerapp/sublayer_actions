require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for appending a new row of data to a specified Google Sheets document.
# This action is useful for data logging or result tracking in applications that integrate with Google Sheets.
#
# It is initialized with a spreadsheet_id and values for the new row.
# It returns the response from the Google Sheets API to confirm the row was appended successfully.
#
# Example usage: When you want to log output data from an AI process into a Google Sheets document for easy viewing and sharing.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  SCOPE = 'https://www.googleapis.com/auth/spreadsheets'

  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    authorize
  end

  def call
    service = Google::Apis::SheetsV4::SheetsService.new
    service.authorization = @credentials

    value_range = Google::Apis::SheetsV4::ValueRange.new(values: [@values])

    begin
      response = service.append_spreadsheet_value(@spreadsheet_id, @range, value_range, value_input_option: 'RAW')
      Sublayer.configuration.logger.log(:info, "Row appended successfully to Google Sheets")
      response.updates.updated_range
    rescue Google::Apis::Error => e
      error_message = "Error appending row to Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def authorize
    @credentials = Google::Auth.get_application_default([SCOPE])
  rescue StandardError => e
    error_message = "Google Sheets authorization failed: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end
