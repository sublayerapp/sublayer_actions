require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

# Description: Sublayer::Action responsible for appending a row to a Google Sheet.
#
# It is initialized with spreadsheet_id, range, and values (the row to append).
# It returns the updated range of the sheet.
#
# Example usage: When you want to log data, report metrics, or collect information in a Google Sheet from an AI process.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  TOKEN_PATH = 'token.yaml'.freeze
  CREDENTIALS_PATH = 'credentials.json'.freeze
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values # Should be an array of arrays
  end

  def call
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = 'Sublayer Google Sheets Integration'
    service.authorization = authorize

    value_range_object = Google::Apis::SheetsV4::ValueRange.new(
      values: @values
    )

    begin
      result = service.append_spreadsheet_value(
        @spreadsheet_id,
        @range,
        value_range_object,
        value_input_option: 'USER_ENTERED'
      )

      Sublayer.configuration.logger.log(:info, "Row appended successfully to Google Sheet \#{@spreadsheet_id} at range \#{@range}")
      result.updates.updated_range
    rescue Google::Apis::Error => e
      error_message = "Error appending to Google Sheet: \#{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user will need to open the URL in a browser, enter the authorization
  # code, and paste the code into the terminal.
  #
  # @return [Google::Auth::UserRefreshCredentials]
  def authorize
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: TOKEN_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      Sublayer.configuration.logger.log(:info, "Open the following URL in the browser and enter the resulting code after authorization:\n" + url)
      puts 'Your browser has been opened to visit:'
      puts url

      code = ask("Enter the authorization code here: ")
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end

  def ask(question)
    print question
    gets.chomp
  end
end