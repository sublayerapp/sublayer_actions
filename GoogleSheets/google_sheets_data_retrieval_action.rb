require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

# Description: Sublayer::Action responsible for retrieving data from a Google Sheet.
# This action integrates with Google Sheets API to fetch data from a specified spreadsheet and range.
#
# It is initialized with the sheet_id, range, and optionally the output_format (JSON or CSV). It returns the data in the specified format.
#
# Example usage: When you want to dynamically fetch data from a Google Sheet to use in a Sublayer::Generator or for other AI-driven processes.

class GoogleSheetsDataRetrievalAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Sublayer Google Sheets Integration'.freeze
  CREDENTIALS_PATH = 'token.yaml'.freeze
  SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY

  def initialize(sheet_id:, range:, output_format: 'JSON')
    @sheet_id = sheet_id
    @range = range
    @output_format = output_format.upcase # Ensure case-insensitivity
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
    begin
      data = retrieve_data
      format_data(data)
    rescue Google::Apis::Error => e
      error_message = "Error retrieving data from Google Sheets: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error formatting data: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def authorize
    client_id = Google::Auth::ClientId.from_file('credentials.json')
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, SCOPE, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the " \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end


  def retrieve_data
    @service.get_spreadsheet_values(@sheet_id, @range)
  end

  def format_data(data)
    case @output_format
    when 'JSON'
      data.values.to_json
    when 'CSV'
      generate_csv(data.values)
    else
      raise StandardError, "Unsupported output format: #{@output_format}. Please use JSON or CSV."
    end
  end

  def generate_csv(values)
    CSV.generate do |csv|
      values.each do |row|
        csv << row
      end
    end
  end
end