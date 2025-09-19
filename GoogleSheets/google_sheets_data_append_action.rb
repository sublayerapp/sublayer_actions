require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for appending a row of data to a Google Sheets spreadsheet.
# This action facilitates the logging of data or results of operations into a shared spreadsheet for collaborative analysis or record-keeping.
#
# This is initialized with a spreadsheet_id, range, and values to append.
# It returns the updated range of the spreadsheet to verify the append operation was successful.
#
# Example usage: When you want to record the results of an AI computation or event into a Google Sheets document for sharing or archival.

class GoogleSheetsDataAppendAction < Sublayer::Actions::Base
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    authorize_service
  end

  def call
    append_to_sheet
  rescue Google::Apis::Error => e
    error_message = "Google Sheets error during append operation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def authorize_service
    @service.client_options.application_name = 'Sublayer'
    @service.authorization = Google::Auth.get_application_default([SCOPE])
  end

  def append_to_sheet
    value_range = Google::Apis::SheetsV4::ValueRange.new(values: @values)

    result = @service.append_spreadsheet_value(
      @spreadsheet_id,
      @range,
      value_range,
      value_input_option: 'RAW'
    )

    Sublayer.configuration.logger.log(:info, "Data appended successfully to Google Sheets range: #{result.updates.updated_range}")

    result.updates.updated_range
  end
end