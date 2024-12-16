require 'googleauth'
require 'google/apis/sheets_v4'

# Description: Sublayer::Action responsible for appending a row of data to a specified Google Sheet.
# This action allows for integration with data collection workflows by adding new rows to a Google Sheet.
#
# It is initialized with a spreadsheet_id, range, and values to append.
#
# Example usage: When you want to collect data from a workflow or AI process and store it in a Google Sheet for later analysis.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    authorize_service
  end

  def call
    begin
      append_values
      Sublayer.configuration.logger.log(:info, "Row appended successfully to spreadsheet \\#{@spreadsheet_id}")
    rescue Google::Apis::ClientError => e
      error_message = "Error appending row to Google Sheet: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def authorize_service
    scopes = ['https://www.googleapis.com/auth/spreadsheets']
    @service.authorization = Google::Auth.get_application_default(scopes)
  end

  def append_values
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: [@values])
    @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'RAW')
  end
end
