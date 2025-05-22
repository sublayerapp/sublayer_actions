require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for adding a new row to a Google Sheet.
# This action facilitates automated data entry or logging based on LLM outputs.
#
# Example usage: When you want to record outputs from an LLM to a Google Sheet for analysis or record-keeping.

class GoogleSheetsAddRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = initialize_service
  end

  def call
    append_values
  rescue Google::Apis::Error => e
    error_message = "Error adding row to Google Sheet: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def initialize_service
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = 'Sublayer Integration'
    service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/spreadsheets"])
    service
  end

  def append_values
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: [@values])
    result = @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'USER_ENTERED')
    Sublayer.configuration.logger.log(:info, "Successfully added row to Google Sheet: #{result.updates.updated_range}")
    result
  end
end
