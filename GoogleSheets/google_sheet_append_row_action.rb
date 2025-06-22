require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

# Description: Sublayer::Action responsible for appending a row to a Google Sheet.
# This action allows for logging or tracking data in a structured spreadsheet format
# using the Google Sheets API.
#
# Requires: 'google/apis/sheets_v4', 'googleauth', 'googleauth/stores/file_token_store' gems
# $ gem install google-api-client
#
# It is initialized with the spreadsheet_id, range, and values to append.
# It returns the updated range to confirm the row was appended successfully.
#
# Example usage: When you want to log AI-generated data points to a Google Sheet for record-keeping.

class GoogleSheetAppendRowAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:, values:)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = 'Sublayer Action'
    @service.authorization = authorize
  end

  def call
    begin
      value_range_object = Google::Apis::SheetsV4::ValueRange.new(range: @range, values: [@values])
      result = @service.append_spreadsheet_value(@spreadsheet_id, @range, value_range_object, value_input_option: 'RAW')
      Sublayer.configuration.logger.log(:info, "Row appended successfully to Google Sheet with updated range: #{result.updates.updated_range}")
      result.updates.updated_range
    rescue Google::Apis::Error => e
      error_message = "Error appending row to Google Sheet: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def authorize
    client_id = Google::Auth::ClientId.from_file('path/to/credentials.json')
    token_store = Google::Auth::Stores::FileTokenStore.new(file: 'path/to/tokens.yaml')
    authorizer = Google::Auth::UserAuthorizer.new(client_id, Google::Apis::SheetsV4::AUTH_SPREADSHEETS, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the resulting code after authorization:"
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
end
