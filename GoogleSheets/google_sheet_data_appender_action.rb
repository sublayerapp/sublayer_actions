require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action responsible for appending data to a specific Google Sheet.
# This action is intended for use when you need to log data or create collaborative reports in workflows.
#
# Initializes with spreadsheet_id, range, and values to append.
# Requires OAuth 2.0 credentials for authentication.
# Returns the update response from Google Sheets API.
#
# Example usage: Append new log entries or data points to a Google Sheet as part of an AI-driven process.

class GoogleSheetDataAppenderAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Sublayer Actions'
  CREDENTIALS_PATH = 'credentials.json'
  TOKEN_PATH = 'token.yaml'
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
    begin
      response = append_values
      Sublayer.configuration.logger.log(:info, "Data appended successfully to the Google Sheet range \\"#{@range}\\"")
      response
    rescue Google::Apis::Error => e
      error_message = "Google Sheets API error: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "General error occurred while appending data: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def append_values
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: @range, values: @values)
    @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'USER_ENTERED')
  end

  def authorize
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    unless credentials
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      logger.info "Open the following URL in your browser and authorize the application: #{url}"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
end
