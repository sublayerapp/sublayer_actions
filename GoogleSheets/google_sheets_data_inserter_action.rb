require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action responsible for inserting data into a Google Sheets spreadsheet.
# This action allows for real-time data updates and storage in Google Sheets, facilitating subsequent analysis.
#
# It is initialized with spreadsheet_id, range, and values.
# It returns a success message with the updated range upon successful execution.
#
# Example usage: Update a Google Sheets spreadsheet with data generated from an AI process.

class GoogleSheetsDataInserterAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Sublayer Google Sheets API'
  CREDENTIALS_PATH = 'path/to/credentials.json' # Update this with the path to your credentials.json
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
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: @range, values: @values)
    begin
      response = @service.update_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'RAW')
      Sublayer.configuration.logger.log(:info, "Data successfully inserted into Google Sheets: \
Updated range: \\#{response.updated_range}")
      response.updated_range
    rescue Google::Apis::ServerError => e
      error_message = "Server error: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ClientError => e
      error_message = "Client error: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::AuthorizationError => e
      error_message = "Authorization error: \\#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def authorize
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the resulting code after authorization:\n\n\#{url}\n"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
end