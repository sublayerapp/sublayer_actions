require 'google_drive'

# Description: Sublayer::Action responsible for appending rows of data to a specified Google Sheets document.
# This action allows for easy logging or exporting of data to Google Sheets
# for analysis or record-keeping purposes.
#
# Requires: "google_drive" gem
# $ gem install google_drive
# Or add `gem 'google_drive'` to your Gemfile
#
# It is initialized with a spreadsheet_key and an array of rows.
# Each row should also be an array of cell values.
# It confirms successful append operation by returning true.
#
# Example usage: When you have data generated from an AI process
# that you want to log or analyze in Google Sheets.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_key:, rows: [])
    @spreadsheet_key = spreadsheet_key
    @rows = rows
    @session = GoogleDrive::Session.from_config("config.json")
  end

  def call
    begin
      sheet = open_sheet
      append_rows(sheet)
      Sublayer.configuration.logger.log(:info, "Successfully appended rows to Google Sheets with key: #{@spreadsheet_key}")
      true
    rescue StandardError => e
      error_message = "Error appending rows to Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def open_sheet
    begin
      spreadsheet = @session.spreadsheet_by_key(@spreadsheet_key)
      spreadsheet.worksheets[0]
    rescue Google::Apis::ClientError => e
      error_message = "Error accessing Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  def append_rows(sheet)
    @rows.each do |row|
      sheet.insert_rows(sheet.num_rows + 1, [row])
    end
    sheet.save
  end
end
