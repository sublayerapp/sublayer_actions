require 'google_drive'

# Description: Sublayer::Action responsible for appending a new row with specified data to a Google Sheets document.
# Useful for recording outputs or logs from AI workflows.

class GoogleSheetsRowAppenderAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, worksheet_title:, row_data: [])
    @session = GoogleDrive::Session.from_service_account_key(ENV['GOOGLE_SERVICE_ACCOUNT_JSON'])
    @spreadsheet_id = spreadsheet_id
    @worksheet_title = worksheet_title
    @row_data = row_data
  end

  def call
    begin
      spreadsheet = @session.spreadsheet_by_key(@spreadsheet_id)
      worksheet = spreadsheet.worksheet_by_title(@worksheet_title)

      # Append the row data
      worksheet.insert_rows(worksheet.num_rows + 1, [@row_data])
      worksheet.save

      Sublayer.configuration.logger.log(:info, "Row appended successfully to Google Sheets.")
      true
    rescue Google::Apis::Error => e
      error_message = "Error appending row to Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
