require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
CREDENTIALS_PATH = 'token.yaml'.freeze

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action integrates with Google Calendar using the google-api-client gem.
#
# It is initialized with a calendar_id, start_time, end_time, summary, and optional description.
# It returns the event ID of the created event.
#
# Example usage: When you want to automatically create calendar events based on AI-generated schedules or reminders.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, start_time:, end_time:, summary:, description: nil)
    @calendar_id = calendar_id
    @start_time = start_time # Expects a datetime string in ISO 8601 format
    @end_time = end_time     # Expects a datetime string in ISO 8601 format
    @summary = summary
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
  # @return [Google::Auth::UserRefreshCredentials]
  def authorize
    client_id = Google::Auth::ClientId.from_file(ENV['GOOGLE_CLIENT_SECRETS_PATH'])
    token_store = Google::Auth::Stores::FileTokenStore.new(file: CREDENTIALS_PATH)
    authorizer = Google::Auth::UserAuthorizer.new(client_id, Google::Apis::CalendarV3::AUTH_CALENDAR, token_store)
    user_id = 'default'
    credentials = authorizer.get_credentials(user_id)
    if credentials.nil?
      url = authorizer.get_authorization_url(base_url: OOB_URI)
      puts 'Open the following URL in the browser and enter the ' \
           'resulting code after authorization:
'
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

  def create_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @start_time,
        time_zone: 'UTC'
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @end_time,
        time_zone: 'UTC'
      )
    )

    @client.insert_event(@calendar_id, event)
  end
end