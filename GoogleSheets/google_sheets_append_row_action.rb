require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for appending a new row of data to a specified Google Sheets document.
# Useful for logging data or results from AI processes into Google Sheets automatically.
#
# It is initialized with a spreadsheet_id, range, and values (an array of rows to append).
# It does not return anything, but raises an error if the operation fails.
#
# Example usage: When you want to log outputs from an AI process directly into a Google Sheets document for tracking or analysis.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS
  
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = Google::Auth.get_application_default([SCOPE])
  end

  def call
    begin
      append_values
      Sublayer.configuration.logger.log(:info, "Successfully appended row(s) to spreadsheet \\"
        "#{@spreadsheet_id}" at range "#{@range}")
    rescue Google::Apis::Error => e
      error_message = "Error appending row(s) to Google Sheets: \\"
        "#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def append_values
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: @range, values: @values)
    @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'RAW')
  end
end
