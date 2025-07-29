require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for updating rows in Google Sheets.
# This action is useful for logging AI-generated data or insights in a collaborative spreadsheet environment.
#
# It is initialized with a spreadsheet_id, range, and values to update the sheet with.
#
# Example usage: When you want to log insights from an AI model into a shared Google Sheet.

class GoogleSheetsUpdateRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = 'Sublayer Actions'
    authorize
  end

  def call
    update_sheet
  rescue Google::Apis::Error => e
    error_message = "Error updating Google Sheet: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "General error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def authorize
    scopes = [Google::Apis::SheetsV4::AUTH_SPREADSHEETS]
    @service.authorization = Google::Auth.get_application_default(scopes)
  end

  def update_sheet
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: @values)
    @service.update_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'RAW')
    Sublayer.configuration.logger.log(:info, "Successfully updated Google Sheet #{@spreadsheet_id} in range #{@range}")
  end
end
