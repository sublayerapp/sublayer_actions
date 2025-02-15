require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

# Description: Sublayer::Action responsible for appending a new row of data to a specified Google Sheets document.
# This action enables easy logging and data collection from AI workflows into spreadsheets.
#
# It is initialized with a spreadsheet_id, range, and values (an array representing a row of data).
# It appends the data to the specified range in the Google Sheets document.
#
# Example usage: When you want to log outputs from an AI process into a Google Sheet for tracking or analysis purposes.

class GoogleSheetsDataAppendAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Sublayer Google Sheets API Ruby'.freeze
  CREDENTIALS_PATH = 'path/to/credentials.json'.freeze
  TOKEN_PATH = 'path/to/token.yaml'.freeze
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = initialize_service
  end

  def call
    begin
      value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: [@values])
      response = @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'USER_ENTERED')

      Sublayer.configuration.logger.log(:info, "Data appended successfully to Google Sheet in range #{@range}")
      response.updates.updated_range
    rescue Google::Apis::ClientError => e
      error_message = "Error appending data to Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error during Google Sheets operation: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def initialize_service
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(CREDENTIALS_PATH),
      scope: SCOPE)

    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorizer
    service
  end
end