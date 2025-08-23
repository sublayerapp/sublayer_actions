require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action responsible for fetching data from a specified Google Sheets spreadsheet.
# This action integrates with Google Sheets using the Sheets API, fetching data for use in AI workflows.
#
# It is initialized with a spreadsheet_id and range, returning the fetched data in a friendly format.
# Ideal for integrating spreadsheet data into AI-driven workflows, such as generating reports.

class GoogleSheetsDataFetchAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Sublayer Google Sheets Data Fetch'
  CREDENTIALS_PATH = 'path/to/credentials.json'
  TOKEN_PATH = 'token.yaml'
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY

  def initialize(spreadsheet_id:, range:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
    begin
      response = @service.get_spreadsheet_values(@spreadsheet_id, @range)
      parse_response(response)
    rescue Google::Apis::Error => e
      error_message = "Error fetching data from Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "An unexpected error occurred: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
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
      puts "Open the following URL in the browser and enter the resulting code after authorization:
" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def parse_response(response)
    values = response.values
    return "No data found." if values.nil? || values.empty?

    # Convert the response to a friendly format
    values.map { |row| row.join(", ") }
  end
end