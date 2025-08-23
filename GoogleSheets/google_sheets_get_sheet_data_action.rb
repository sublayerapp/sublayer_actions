require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

# Description: Sublayer::Action responsible for retrieving data from a Google Sheet.
#
# This action takes a sheet ID and range as input, and returns the data from the sheet.
#
# It is initialized with a sheet_id, range, and optional parameters like headers.
#
# Example usage: When you want to feed structured data from a Google Sheet into a Sublayer::Generator or agent.

class GoogleSheetsGetSheetDataAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  TOKEN_PATH = 'token.yaml'.freeze
  CREDENTIALS_PATH = 'credentials.json'.freeze
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY

  def initialize(sheet_id:, range:)
    @sheet_id = sheet_id
    @range = range
  end

  def call
    begin
      service = get_sheets_service
      response = service.get_spreadsheet_values(@sheet_id, @range)

      if response.values.nil? || response.values.empty?
        Sublayer.configuration.logger.log(:warn, "No data found in sheet \#{@sheet_id} range \#{@range}")
        return []
      end

      Sublayer.configuration.logger.log(:info, "Successfully retrieved data from sheet \#{@sheet_id} range \#{@range}")
      response.values
    rescue Google::Apis::Error => e
      error_message = "Error retrieving data from Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def get_sheets_service
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = 'Sublayer Action'
    service.authorization = authorize
    service
  end

  def authorize
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the " \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end
end