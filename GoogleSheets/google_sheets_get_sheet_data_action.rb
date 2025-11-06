require 'google/apis/sheets_v4'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
CREDENTIALS_PATH = 'token.yaml'.freeze

# Description: Sublayer::Action responsible for retrieving data from a Google Sheet.
# This action allows AI agents to analyze and process tabular data.
#
# It is initialized with a spreadsheet_id and range, and returns a 2D array of values.
#
# Example usage: When you want to analyze data from a Google Sheet in your Sublayer workflow.

class GoogleSheetsGetSheetDataAction < Sublayer::Actions::Base
  def initialize(spreadsheet_id:, range:)
    @spreadsheet_id = spreadsheet_id
    @range = range
  end

  def call
    begin
      data = get_sheet_data
      Sublayer.configuration.logger.log(:info, "Successfully retrieved data from Google Sheet \#{@spreadsheet_id}!\#{@range}")
      data
    rescue Google::Apis::Error => e
      error_message = "Error retrieving Google Sheet data: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  ##
  # Ensure valid credentials, either by fetching from the save file
  # or intitiating an OAuth dance.
  #
  # @return [Google::Auth::UserRefreshCredentials] OAuth credentials
  def authorize
    client_id = Google::Auth::ClientId.from_file(ENV['GOOGLE_APPLICATION_CREDENTIALS'])
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, Google::Apis::SheetsV4::AUTH_SPREADSHEETS_READONLY, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the ' \
           'resulting code after authorization:'
      puts url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id,
        code: code,
        base_url: OOB_URI
      )
    end
    credentials
  end

  def get_sheet_data
    # Initialize the Sheets API
    service = Google::Apis::SheetsV4::SheetsService.new
    service.client_options.application_name = 'Sublayer Action'
    service.authorization = authorize

    # Prints the names and majors of students in a sample spreadsheet:
    # https://docs.google.com/spreadsheets/d/1BxiMVs0XRA5nFMdKvBdBZjgmUUqptAu74PymLdf9Zf0/edit
    # spreadsheet_id = '1BxiMVs0XRA5nFMdKvBdBZjgmUUqptAu74PymLdf9Zf0'
    # range = 'Class Data!A2:E'
    response = service.get_spreadsheet_values(@spreadsheet_id, @range)
    # puts "No data found.\n" if response.values.empty?
    # response.values.each do |row|
    #   # Print columns A and E, which correspond to indices 0 and 4.
    #   puts "\#{row[0]}, \#{row[4]}"
    # end
    response.values
  end
end