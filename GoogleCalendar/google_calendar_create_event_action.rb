require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
CREDENTIALS_PATH = 'token.yaml'.freeze

# Description: Sublayer::Action responsible for creating a new event in a Google Calendar.
# It is initialized with calendar_id, start_time, end_time, and summary. Returns the event ID.
#
# Example usage: When you want to automatically create calendar events based on AI-driven scheduling or task management.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, start_time:, end_time:, summary:)
    @calendar_id = calendar_id
    @start_time = start_time # Should be an ISO 8601 timestamp string
    @end_time = end_time     # Should be an ISO 8601 timestamp string
    @summary = summary
    @client = Google::Apis::CalendarV3::CalendarService.new
    @client.client_options.application_name = 'Sublayer Google Calendar Integration'
    @client.authorization = authorize
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time, time_zone: 'UTC'),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time, time_zone: 'UTC')
    )

    begin
      result = @client.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created: #{result.id}")
      result.id
    rescue Google::Apis::ServerError => e
      error_message = "Google Calendar API returned a server error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ClientError => e
      error_message = "Invalid request: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user will be prompted to visit a URL in a web browser and enter a
  # verification code of the result. Once authorized, the service object now has
  # access to the user's calendar.
  #
  # @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
  def authorize
    client_id = Google::Auth::ClientId.from_file('credentials.json')
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, Google::Apis::CalendarV3::AUTH_CALENDAR, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts "Open the following URL in the browser and enter the " \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id,
        code: code,
        base_url: OOB_URI
      )
    end
    credentials
  end
end
