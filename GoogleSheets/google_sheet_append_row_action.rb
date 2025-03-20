require 'google_drive'

# Description: Sublayer::Action responsible for appending a row of data to a Google Sheet.
# This action allows for logging results or tracking metrics from AI workflows.
#
# Requires: 'google_drive' gem
# $ gem install google_drive
# Or add `gem 'google_drive'` to your Gemfile
#
# It is initialized with a spreadsheet key, worksheet title or index, and an array of row data.
# Example usage: When you want to log AI-generated insights or metrics into a Google Sheet for further analysis.

class GoogleSheetAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_key:, worksheet_title_or_index:, row_data:)
    @spreadsheet_key = spreadsheet_key
    @worksheet_title_or_index = worksheet_title_or_index
    @row_data = row_data
    @session = GoogleDrive::Session.from_config("config.json")
  end

  def call
    begin
      worksheet = find_worksheet
      worksheet.insert_rows(worksheet.num_rows + 1, [@row_data])
      worksheet.save
      Sublayer.configuration.logger.log(:info, "Row appended successfully to the Google Sheet")
      true
    rescue GoogleDrive::Error => e
      error_message = "Error appending row to Google Sheet: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def find_worksheet
    spreadsheet = @session.spreadsheet_by_key(@spreadsheet_key)
    if @worksheet_title_or_index.is_a?(String)
      spreadsheet.worksheet_by_title(@worksheet_title_or_index)
    else
      spreadsheet.worksheets[@worksheet_title_or_index]
    end
  end
end
