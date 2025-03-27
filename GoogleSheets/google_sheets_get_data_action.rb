require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action responsible for retrieving data from a Google Sheet.
#
# This action allows agents to access structured data in a Google Sheet for decision-making or prompt augmentation.
#
# It is initialized with spreadsheet_id, range, and optionally credentials_path.
# It returns the data from the specified range in the Google Sheet.
#
# Example usage: When you want to use data from a Google Sheet to inform an AI agent's decisions or augment a prompt.

class GoogleSheetsGetDataAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Sublayer Google Sheets'.freeze

  def initialize(spreadsheet_id:, range:, credentials_path: nil, token_path: nil)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @credentials_path = credentials_path || ENV['GOOGLE_APPLICATION_CREDENTIALS']
    @token_path = token_path || 'token.yaml'
  end

  def call
    begin
      service = get_sheets_service
      response = service.get_spreadsheet_values(@spreadsheet_id, @range)

      if response.values.nil? || response.values.empty?
        Sublayer.configuration.logger.log(:warn, "No data found in range \#{@range} of spreadsheet \#{@spreadsheet_id}")
        []
      else
        Sublayer.configuration.logger.log(:info, "Successfully retrieved data from Google Sheet \#{@spreadsheet_id}, range \#{@range}")
        response.values
      end
    rescue Google::Apis::Error => e
      error_message = "Error retrieving data from Google Sheets: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization request. If authorization
  # request, the user intervention.s required.
  #
  # @param service [Google::Apis::SheetsV4::SheetsService] the API service object
  # @return [Google::Apis::SheetsV4::SheetsService] updated API service object with valid credentials
  def authorize
    client_id = Google::Auth::ClientId.from_file(@credentials_path)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: @token_path)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      Sublayer.configuration.logger.log(:info, "Open the following URL in the browser and enter the resulting code after authorization:\n" + url)
      puts "Open the following URL in the browser and enter the resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def get_sheets_service
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = APPLICATION_NAME
    service.authorization = authorize
    service
  end
end