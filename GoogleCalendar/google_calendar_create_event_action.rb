require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
CREDENTIALS_PATH = 'token.yaml'.freeze

# Description: Sublayer::Action responsible for creating a new event in a Google Calendar.
#
# This action allows for easy integration with Google Calendar, enabling automated scheduling based on AI-driven processes.
#
# It is initialized with calendar_id, event_title, start_time, end_time, and optional description.
# It returns the event ID of the created event.
#
# Example usage: When you want to automatically schedule meetings or tasks based on AI-generated summaries or recommendations.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_title:, start_time:, end_time:, description: nil)
    @calendar_id = calendar_id
    @event_title = event_title
    @start_time = start_time # Should be an ISO 8601 timestamp string
    @end_time = end_time     # Should be an ISO 8601 timestamp string
    @description = description
    @client = Google::Apis::CalendarV3::CalendarService.new
    @client.authorization = authorize
  end

  def call
    event = create_event
    Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully: #{event.id}")
    event.id
  rescue Google::Apis::Error => e
    error_message = "Error creating Google Calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  ##
  # Ensure valid credentials, either by restoring from the saved credentials
  # files or intitiating an OAuth2 authorization. If authorization is required,
  # the user's default browser will be launched to approve the request.
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
      puts 'Open the following URL in the browser and enter the ' \
           "resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end

  def create_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_title,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time),
    )

    @client.insert_event(@calendar_id, event)
  end
end