require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for updating specified cells in a Google Sheets document.
# This action is useful for workflows that require data logging or analysis in Google Sheets,
# expanding the cross-integration capabilities of Sublayer.
#
# It is initialized with a spreadsheet_id, range, and values, and updates the cells accordingly.
#
# Example usage: When you need to log data or write analysis results into a Google Sheets document
# as part of an AI-driven workflow.

class GoogleSheetsDataUpdaterAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = "Sublayer-GoogleSheets-Integration"
    @service.authorization = Google::Auth.get_application_default(["https://www.googleapis.com/auth/spreadsheets"])
  end

  def call
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: @values)

    begin
      @service.update_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'RAW')
      Sublayer.configuration.logger.log(:info, "Successfully updated Google Sheet with ID #{@spreadsheet_id} at range #{@range}")
    rescue Google::Apis::ClientError => e
      error_message = "Error updating Google Sheet: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end
end
