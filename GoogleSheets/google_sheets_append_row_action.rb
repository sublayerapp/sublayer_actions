require 'google_drive'

# Description: Sublayer::Action responsible for appending a row of data to a specified Google Sheets document.
# This action is intended for logging outputs from AI processes or maintaining a live record of generated insights.
#
# Requires: google_drive gem
# $ gem install google_drive
# Or add `gem 'google_drive'` to your Gemfile
#
# It is initialized with a spreadsheet_key, worksheet_title, and row_data (an array of values).
# It returns true if the row was successfully appended.
#
# Example usage: When you want to log data outputs from an AI process to keep a record in Google Sheets.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_key:, worksheet_title:, row_data:)
    @spreadsheet_key = spreadsheet_key
    @worksheet_title = worksheet_title
    @row_data = row_data
    @session = GoogleDrive::Session.from_service_account_key('path/to/service_account.json')
  end

  def call
    begin
      worksheet = get_worksheet
      worksheet.insert_rows(worksheet.num_rows + 1, [@row_data])
      worksheet.save
      Sublayer.configuration.logger.log(:info, "Successfully appended row to Google Sheets")
      true
    rescue GoogleDrive::Error => e
      error_message = "Google Sheets error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error appending row to Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def get_worksheet
    spreadsheet = @session.spreadsheet_by_key(@spreadsheet_key)
    spreadsheet.worksheet_by_title(@worksheet_title)
  end
end
