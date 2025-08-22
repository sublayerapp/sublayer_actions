require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action responsible for appending data to a Google Sheets spreadsheet.
# This allows for easy integration with data analysis workflows where results or logs need to be stored systematically over time.
#
# It is initialized with the spreadsheet_id, range, and values to append.
# It logs success or raises an error in case of failure.
#
# Example usage: When you want to log system outputs or analysis results regularly to a Google Sheets file for tracking and further analysis.

class GoogleSheetsDataAppendAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Sublayer Google Sheets API'.freeze
  CREDENTIALS_PATH = 'credentials.json'.freeze
  TOKEN_PATH = 'token.yaml'.freeze
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
      value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: @range, values: @values)
      @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'USER_ENTERED')
      Sublayer.configuration.logger.log(:info, "Data appended successfully to Google Sheets")
    rescue Google::Apis::Error => e
      error_message = "Error appending data to Google Sheets: #{e.message}"
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
      puts "Open the following URL in the browser and enter the resulting code after authorization:\n#{url}"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
end
