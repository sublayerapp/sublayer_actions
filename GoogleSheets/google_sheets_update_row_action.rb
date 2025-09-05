require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for creating or updating rows in Google Sheets.
# This action is useful for logging AI model outputs or metrics directly into a spreadsheet for monitoring and analysis.
#
# It is initialized with a spreadsheet_id, range, values (array), and operation (either 'create' or 'update').
# It executes the operation specified and returns a confirmation message upon successful execution.
#
# Example usage: Use it to log outputs of an AI model to a Google Sheet for later analysis.

class GoogleSheetsUpdateRowAction < Sublayer::Actions::Base
  SCOPE = ["https://www.googleapis.com/auth/spreadsheets"]

  def initialize(spreadsheet_id:, range:, values:, operation: 'update')
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @operation = operation.downcase
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = Google::Auth.get_application_default(SCOPE)
  end

  def call
    case @operation
    when 'create'
      append_row
    when 'update'
      update_row
    else
      raise ArgumentError, "Invalid operation: \\#{@operation}. Use 'create' or 'update'."
    end
  rescue Google::Apis::Error => e
    error_message = "Google Sheets API error: \\#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  rescue StandardError => e
    error_message = "Unexpected error: \\#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def append_row
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: [@values])
    @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'RAW')
    Sublayer.configuration.logger.log(:info, "Row appended successfully to spreadsheet with ID: \\#{@spreadsheet_id}")
  end

  def update_row
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: [@values])
    @service.update_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'RAW')
    Sublayer.configuration.logger.log(:info, "Row updated successfully in spreadsheet with ID: \\#{@spreadsheet_id}")
  end
end
