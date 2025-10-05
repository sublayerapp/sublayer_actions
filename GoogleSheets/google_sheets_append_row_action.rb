require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for appending a row of data to a specified Google Sheets document.
# This action facilitates logging data outputs or aggregating results from various AI tasks into a Google Sheet.
#
# Requirements: Ensure that the Google Sheets API is enabled and appropriate credentials are set up.
# Requires: 'google-api-client' gem
# $ gem install google-api-client
#
# It is initialized with a spreadsheet_id, range, and values (an array of values representing a row).
# It appends the data to the specified range and returns a success message with the updated cells count.
#
# Example usage: Use this action to log results from AI processes into a shared Google Sheet for team visibility.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = "Sublayer Google Sheets Integration"
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/spreadsheets"])
  end

  def call
    append_row
  rescue Google::Apis::ServerError => e
    handle_error("Server error: #{e.message}")
  rescue Google::Apis::ClientError => e
    handle_error("Client error: #{e.message}")
  rescue Google::Apis::AuthorizationError => e
    handle_error("Authorization error: #{e.message}")
  rescue StandardError => e
    handle_error("General error: #{e.message}")
  end

  private

  def append_row
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: [@values])
    result = @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'RAW')
    log_success("Appended row to Google Sheet successfully: #{result.updates.updated_cells} cells updated.")
  end

  def handle_error(message)
    Sublayer.configuration.logger.log(:error, message)
    raise StandardError, message
  end

  def log_success(message)
    Sublayer.configuration.logger.log(:info, message)
    message
  end
end