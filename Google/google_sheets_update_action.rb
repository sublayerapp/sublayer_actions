require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for updating specific cells or ranges in Google Sheets.
# This action enables the integration of AI-processed data into collaborative spreadsheets and dashboards.
#
# Requires: 'google-apis-sheets_v4' and 'googleauth' gems
# $ gem install google-apis-sheets_v4 googleauth
# Or add to your Gemfile:
# gem 'google-apis-sheets_v4'
# gem 'googleauth'
#
# It is initialized with a spreadsheet_id, range, and values to update.
# It returns the updated range as confirmation of the successful update.
#
# Example usage: When you want to update a Google Sheet with AI-generated or processed data.

class GoogleSheetsUpdateAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_APPLICATION_CREDENTIALS']),
      scope: Google::Apis::SheetsV4::AUTH_SPREADSHEETS
    )
  end

  def call
    begin
      request_body = Google::Apis::SheetsV4::ValueRange.new(values: @values)
      result = @service.update_spreadsheet_value(
        @spreadsheet_id,
        @range,
        request_body,
        value_input_option: 'USER_ENTERED'
      )
      Sublayer.configuration.logger.log(:info, "Successfully updated Google Sheet: \#{result.updated_range}")
      result.updated_range
    rescue Google::Apis::Error => e
      error_message = "Error updating Google Sheet: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
