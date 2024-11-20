require 'google_drive'

# Description: Sublayer::Action responsible for appending a new row of data to a Google Sheets document.
# This action is helpful for dynamically logging or tracking data as your AI models run or analyze information.
#
# Requires: 'google_drive' gem
# $ gem install google_drive
# Or add `gem 'google_drive'` to your Gemfile
#
# It is initialized with a spreadsheet_key and row_data (an array of cell values).
# Example usage: To log AI model predictions or results in a Google Sheets document for further analysis.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_key:, row_data:)
    @spreadsheet_key = spreadsheet_key
    @row_data = row_data
    @session = GoogleDrive::Session.from_config("config.json")
  end

  def call
    begin
      worksheet = @session.spreadsheet_by_key(@spreadsheet_key).worksheets.first
      worksheet.append_row(@row_data)
      worksheet.save
      Sublayer.configuration.logger.log(:info, "Successfully appended a new row to the Google Sheets document")
    rescue Google::Apis::Error => e
      error_message = "Google API Error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error appending row to Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
