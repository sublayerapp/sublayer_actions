require 'google_drive'

# Description: Sublayer::Action responsible for importing specific cell ranges or entire sheets from Google Sheets.
# This action allows integration with Google Sheets to fetch data for further processing in Sublayer workflows.
#
# It is initialized with a spreadsheet_key, range, and optionally worksheet_title.
# It returns the fetched data from Google Sheets.
#
# Example usage: When you want to import data from a Google Sheet for analysis or as part of an AI-driven process.

class GoogleSheetsDataImportAction < Sublayer::Actions::Base
  def initialize(spreadsheet_key:, range:, worksheet_title: nil)
    @spreadsheet_key = spreadsheet_key
    @range = range
    @worksheet_title = worksheet_title
    @session = GoogleDrive::Session.from_service_account_key(ENV['GOOGLE_DRIVE_SERVICE_ACCOUNT_KEY'])
  end

  def call
    begin
      worksheet = get_worksheet
      fetch_data(worksheet)
    rescue Google::Apis::Error => e
      error_message = "Error importing data from Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def get_worksheet
    spreadsheet = @session.spreadsheet_by_key(@spreadsheet_key)
    if @worksheet_title
      spreadsheet.worksheet_by_title(@worksheet_title)
    else
      spreadsheet.worksheets.first
    end
  end

  def fetch_data(worksheet)
    data = worksheet[@range]
    Sublayer.configuration.logger.log(:info, "Successfully fetched data from Google Sheets")
    data
  end
end