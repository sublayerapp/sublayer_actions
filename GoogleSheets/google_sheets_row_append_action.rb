require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for appending a new row of data to a Google Sheets document.
# This action facilitates data logging and reporting tasks by integrating with Google Sheets API.
#
# Usage Example: Automatically log AI-generated insights or report data into a Google Sheet for tracking or further analysis in AI-driven workflows.

class GoogleSheetsRowAppendAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = 'Sublayer'
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/spreadsheets"])
  end

  def call
    begin
      log_info('Appending row to Google Sheets')
      append_row_to_sheet
      log_info('Row appended successfully')
    rescue Google::Apis::Error => e
      error_message = "Error appending row to Google Sheets: #{e.message}"
      log_error(error_message)
      raise StandardError, error_message
    end
  end

  private

  def append_row_to_sheet
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: [@values])
    @service.append_spreadsheet_value(
      @spreadsheet_id,
      @range,
      value_range_object,
      value_input_option: 'RAW'
    )
  end

  def log_info(message)
    Sublayer.configuration.logger.log(:info, message)
  end

  def log_error(message)
    Sublayer.configuration.logger.log(:error, message)
  end
end