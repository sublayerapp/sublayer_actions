require 'google/apis/sheets_v4'
require 'googleauth'

# Description: Sublayer::Action responsible for appending a new row to a specified Google Sheet.
# It allows for integration with Google Sheets for logging or collaborative data analysis in AI-driven workflows.
#
# Example usage: Use this action to log AI-generated results or data points into a Google Sheet for further analysis or sharing.

class GoogleSheetsAppendRowAction < Sublayer::Actions::Base
  SPREADSHEETS_SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

  def initialize(spreadsheet_id:, range:, values:, credentials_path: nil)
    @spreadsheet_id = spreadsheet_id
    @range = range
    @values = values
    @credentials_path = credentials_path || ENV['GOOGLE_CREDENTIALS_PATH']
    @service = Google::Apis::SheetsV4::SheetsService.new
    @service.client_options.application_name = 'Sublayer Actions'
  end

  def call
    authorize_service
    append_values
  rescue Google::Apis::Error => e
    error_message = "Error appending row to Google Sheet: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  def authorize_service
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(@credentials_path),
      scope: SPREADSHEETS_SCOPE
    )
    @service.authorization = authorizer
    @service.authorization.fetch_access_token!
  end

  def append_values
    value_range_object = Google::Apis::SheetsV4::ValueRange.new(values: [@values])
    result = @service.append_spreadsheet_value(
      @spreadsheet_id,
      @range,
      value_range_object,
      value_input_option: 'RAW'
    )
    Sublayer.configuration.logger.log(:info, "Successfully appended row to Google Sheet: #{result.updates.updated_range}")
  end
end
