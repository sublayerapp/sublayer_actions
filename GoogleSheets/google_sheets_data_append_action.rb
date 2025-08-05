require 'google_drive'

# Description: Sublayer::Action responsible for appending new rows of data to a specified Google Sheet.
# This action allows for logging data or results directly from AI workflows into spreadsheets for tracking purposes.
#
# It is initialized with a spreadsheet_key and the data to append as an array of arrays.
# It returns the updated number of rows in the sheet after appending the data.
#
# Example usage: When you want to log results from an AI process into Google Sheets for analysis or record-keeping.

class GoogleSheetsDataAppendAction < Sublayer::Actions::Base
  def initialize(spreadsheet_key:, data: [])
    @spreadsheet_key = spreadsheet_key
    @data = data
    @session = GoogleDrive::Session.from_config('config.json')
  end

  def call
    worksheet = @session.spreadsheet_by_key(@spreadsheet_key).worksheets.first
    @data.each do |row|
      worksheet.insert_rows(worksheet.num_rows + 1, [row])
    end
    worksheet.save
    Sublayer.configuration.logger.log(:info, "Appended #{data.size} rows successfully to Google Sheets with key: #{@spreadsheet_key}")
    worksheet.num_rows
  rescue Google::Apis::Error => e
    error_message = "Google API error during data append: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "General error while appending data to Google Sheets: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end
end