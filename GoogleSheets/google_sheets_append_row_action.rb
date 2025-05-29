require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

# Description: Sublayer::Action responsible for appending a row to a specific Google Sheets spreadsheet and sheet.
# This action is useful for logging and reporting purposes by adding new data entries.
#
# It is initialized with the spreadsheet_id, sheet_name, and row_data.
# On successful execution, it appends the row to the specified sheet.
#
# Example usage: Adding a log entry or updating reporting data in Google Sheets.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Google Sheets API Ruby Quickstart'
  CREDENTIALS_PATH = 'token.yaml'
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

  def initialize(spreadsheet_id:, sheet_name:, row_data:)
    @spreadsheet_id = spreadsheet_id
    @sheet_name = sheet_name
    @row_data = row_data
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
    append_row
  rescue Google::Apis::Error => e
    error_message = "Error appending row to Google Sheet: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def authorize
    client_id = Google::Auth::ClientId.from_file(CREDENTIALS_PATH)
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      puts 'Open the following URL in the browser and enter the resulting code after authorization: '
      puts authorizer.get_authorization_url(base_url: OOB_URI)
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def append_row
    range = "#{@sheet_name}!A:A"
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: [@row_data])
    result = @service.append_spreadsheet_value(@spreadsheet_id, range, value_range_object, value_input_option: 'RAW')
    Sublayer.configuration.logger.log(:info, "A row added successfully to #{@sheet_name} in spreadsheet #{@spreadsheet_id}")
  end
end
