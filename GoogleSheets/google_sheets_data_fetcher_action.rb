require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for fetching data from a specified Google Sheets document.
# This action allows for seamless integration with Google Sheets to fetch and process data in Sublayer workflows.
#
# It is initialized with a spreadsheet_id and a range (e.g., 'Sheet1!A1:D10').
# It returns the data retrieved from the specified range.
#
# Example usage: When you want to fetch data from a Google Sheets document for analysis or further processing in AI workflows.

class GoogleSheetsDataFetcherAction < Sublayer::Actions::Base
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY

  def initialize(spreadsheet_id:, range:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = Google::Auth.get_application_default([SCOPE])
  end

  def call
    begin
      response = @service.get_spreadsheet_values(@spreadsheet_id, @range)
      Sublayer.configuration.logger.log(:info, "Data fetched successfully from Google Sheets")
      response.values
    rescue Google::Apis::ClientError => e
      error_message = "Error fetching data from Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
