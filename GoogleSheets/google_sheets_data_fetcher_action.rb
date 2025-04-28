require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for fetching data from a specified Google Sheets document and sheet.
# This action allows for easy integration with Google Sheets, enabling workflows that require data from spreadsheets.
#
# It is initialized with a spreadsheet_id and a range (e.g., 'Sheet1!A1:D10').
# It returns the data in a format consumable by other processes.
#
# Example usage: When you want to fetch the latest data from a Google Sheet for use in a report or further processing.

class GoogleSheetsDataFetcherAction < Sublayer::Actions::Base
  SCOPE = ['https://www.googleapis.com/auth/spreadsheets.readonly']

  def initialize(spreadsheet_id:, range:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @service = Google::Apis::SheetsV4::SheetsService.new
    authorize
  end

  def call
    begin
      response = @service.get_spreadsheet_values(@spreadsheet_id, @range)
      data = response.values
      Sublayer.configuration.logger.log(:info, "Data fetched successfully from Google Sheets: #{@spreadsheet_id}")
      data
    rescue Google::Apis::Error => e
      error_message = "Error fetching data from Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def authorize
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_APPLICATION_CREDENTIALS']),
      scope: SCOPE
    )
    authorizer.fetch_access_token!
    @service.authorization = authorizer
  end
end
