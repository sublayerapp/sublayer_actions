require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
CREDENTIALS_PATH = 'token.yaml'.freeze

# Description: Sublayer::Action responsible for appending a row to a Google Sheet.
# It is initialized with spreadsheet_id, range, and values.
# It returns the response from the Google Sheets API.
#
# Example usage: When you want to log data, create reports, or update dashboards from AI-driven processes.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = 'Sublayer Google Sheets Integration'
    @service.authorization = authorize
  end

  def call
    begin
      value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: [@values])
      response = @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'USER_ENTERED')

      Sublayer.configuration.logger.log(:info, "Successfully appended row to Google Sheet \#{@spreadsheet_id} at range \#{@range}")
      response
    rescue Google::Apis::Error => e
      error_message = "Error appending row to Google Sheet: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user will need to open the URL in a browser and enter the code that is
  # displayed. Note that the display of the code may not be accessible, depending
  # on the user's configuration.
  #
  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorize
    client_id = Google::Auth::ClientId.from_file(ENV['GOOGLE_APPLICATION_CREDENTIALS'])
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, Google::Apis::SheetsV4::AUTH_SPREADSHEETS, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the ' \
           'resulting code after authorization:
' + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end
end