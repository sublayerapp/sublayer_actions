require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
CREDENTIALS_PATH = 'token.yaml'.freeze

# Description: Sublayer::Action responsible for retrieving data from a specified Google Sheet.
# It uses the Google Sheets API to fetch data and returns it as a 2D array of values.
#
# It is initialized with a spreadsheet_id and range.
# It returns the data from the sheet in a structured format.
#
# Example usage: When you want to use data from a Google Sheet in your Sublayer::Generator prompt or workflow.

class GoogleSheetsGetSheetDataAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:)
    @spreadsheet_id = spreadsheet_id
    @range = range
  end

  def call
    begin
      service = get_google_sheets_service
      data = fetch_sheet_data(service)
      Sublayer.configuration.logger.log(:info, "Successfully retrieved data from Google Sheet \#{@spreadsheet_id}:\#{@range}")
      data
    rescue Google::Apis::Error => e
      error_message = "Error fetching Google Sheet data: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error initializing Google Sheets service: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  ##
  # Ensure valid credentials, either by fetching from the save file
  # or intitiating an OAuth dance. Returns the authorization
  # that should be applied to the API client.
  def authorize
    client_id = Google::Auth::ClientId.from_file(ENV['GOOGLE_SHEETS_CLIENT_SECRET_PATH'])
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the ' \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id,
        code: code,
        base_url: OOB_URI
      )
    end
    credentials
  end

  def get_google_sheets_service
    # Initialize the API
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = 'Sublayer Action'
    service.authorization = authorize
    service
  end

  def fetch_sheet_data(service)
    response = service.get_spreadsheet_values(@spreadsheet_id, @range)
    if response && response.values
      response.values
    else
      []
    end
  end
end