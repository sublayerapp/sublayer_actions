require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action responsible for inserting or updating data in a specified Google Sheets document.
# This action is useful for reporting or storing data generated by an LLM in a structured manner.
#
# Requires: Google API Client for Ruby
# $ gem install google-api-client
# Follow the instructions on https://developers.google.com/sheets/api/quickstart/ruby to set up your credentials.
#
# It is initialized with spreadsheet_id, range, and values
#
# Example usage: When you want to add or update data in a Google Sheets document based on LLM outputs in your Sublayer workflow.

class GoogleSheetsDataInsertionAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Sublayer Google Sheets API'
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
  rescue StandardError => e
    error_message = "Error initializing GoogleSheetsDataInsertionAction: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  def call
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: @values)
    @service.update_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'RAW')
    Sublayer.configuration.logger.log(:info, "Successfully updated Google Sheets document")
  rescue Google::Apis::Error => e
    error_message = "Google Sheets API error: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  # Ensure valid credentials for accessing the Google Sheets API
  def authorize
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in your browser and authorize the application: #{url}"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  rescue StandardError => e
    error_message = "Error during Google Sheets authorization: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end