require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
APPLICATION_NAME = 'Sublayer Google Sheets Action'.freeze
CREDENTIALS_PATH = 'token.yaml'.freeze
SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY

# Description: Sublayer::Action responsible for retrieving data from a specific Google Sheet.
# It is initialized with a sheet_id and range, and returns the data as a 2D array.
#
# Example usage: When you want to retrieve data from a Google Sheet for use in an AI-driven workflow or analysis.

class GoogleSheetsGetDataAction < Sublayer::Actions::Base
  def initialize(sheet_id:, range:)
    @sheet_id = sheet_id
    @range = range
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
    begin
      response = @service.get_spreadsheet_values(@sheet_id, @range)
      Sublayer.configuration.logger.log(:info, "Successfully retrieved data from Google Sheet \#{@sheet_id} range \#{@range}")
      response.values
    rescue Google::Apis::Error => e
      error_message = "Error fetching Google Sheet data: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user will be prompted to visit the URL in a web browser and enter the
  # resulting authorization code to complete the process.
  #
  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorize
    client_id = Google::Auth::ClientId.from_file('credentials.json')
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the '
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end
end