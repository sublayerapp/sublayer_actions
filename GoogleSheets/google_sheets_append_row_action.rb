require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

# Description: Sublayer::Action responsible for appending a row to a Google Sheet.
# This action integrates with Google Sheets API to add a new row with the specified values.
#
# It is initialized with spreadsheet_id, range, and values. It returns the update result.
#
# Example usage: When you want to log data, track metrics, or update spreadsheets with AI-generated insights.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Sublayer Google Sheets'.freeze
  CREDENTIALS_PATH = 'token.yaml'.freeze
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
      value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: [@values])
      response = @service.append_spreadsheet_value(@spreadsheet_id, @range,
                                                   value_range_object, value_input_option: 'USER_ENTERED')

      Sublayer.configuration.logger.log(:info, "Row appended successfully to Google Sheet \#{@spreadsheet_id} at range \#{@range}")
      response
    rescue Google::Apis::Error => e
      error_message = "Error appending row to Google Sheet: \#{e.message}"
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
    client_id = Google::Auth::ClientId.from_file(ENV['GOOGLE_APPLICATION_CREDENTIALS'])
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      Sublayer.configuration.logger.log(:info, "Open the following URL in the browser and enter the resulting code after authorization:\n" + url)
      puts "Open the following URL in the browser and enter the resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end
end