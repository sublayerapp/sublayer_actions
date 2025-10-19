require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for appending data to a specific Google Sheet.
# This action allows for seamless integration of Sublayer-generated data into collaborative spreadsheets.
# It is initialized with a spreadsheet_id, range, and the values to append.
#
# Requires: Google Sheets API client gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# Example usage: When you want to append AI-generated data into a collaborative Google Sheet for analysis or sharing.

class GoogleSheetsDataAppendAction < Sublayer::Actions::Base
  SPREADSHEETS_SCOPE = ['https://www.googleapis.com/auth/spreadsheets']

  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = 'Sublayer Actions'
    @service.authorization = Google::Auth.get_application_default(SPREADSHEETS_SCOPE)
  end

  def call
    append_data
  rescue Google::Apis::Error => e
    error_message = "Error appending data to Google Sheets: \\#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Unexpected error: \\#{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
  end

  private

  def append_data
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: @values)
    response = @service.append_spreadsheet_value(
      @spreadsheet_id,
      @range,
      value_range_object,
      value_input_option: 'USER_ENTERED'
    )

    if response.updates.updated_cells > 0
      Sublayer.configuration.logger.log(:info, "Data appended successfully to Google Sheets in range: #{@range}")
    else
      error_message = "No data was appended to Google Sheets."
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end
end
