require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for updating a cell or range of cells in Google Sheets.
# It can be used to log results or update records with AI-generated data.
#
# It is initialized with spreadsheet_id, range, and values to be updated.
# It returns a response indicating the success of the update operation.
#
# Example usage: When you want to update specific cells in a Google Sheet with AI-generated insights or data.

class GoogleSheetsUpdateAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = 'Sublayer Google Sheets Integration'
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/spreadsheets"])
  end

  def call
    begin
      value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: @values)
      response = @service.update_spreadsheet_value(
        @spreadsheet_id,
        @range,
        value_range_object,
        value_input_option: 'RAW'
      )
      Sublayer.configuration.logger.log(:info, "Updated range #{@range} in spreadsheet #{@spreadsheet_id} successfully.")
      response
    rescue Google::Apis::Error => e
      error_message = "Error updating Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
