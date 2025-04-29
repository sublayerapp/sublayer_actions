require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action responsible for creating an event in a user's Google Calendar.
# This action integrates with Google Calendar using the Google API Client and requires user credentials.
#
# It is initialized with details like calendar_id, event_title, start_time, end_time, description, and participants.
# It returns the ID of the created event.
#
# Example usage: When you want to schedule a meeting or event in a user's Google Calendar based on AI-generated insights or plans.

class GoogleCalendarEventCreatorAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Google Calendar API Ruby Quickstart'.freeze
  CREDENTIALS_PATH = 'path/to/credentials.json'.freeze
  TOKEN_PATH = 'token.yaml'.freeze
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize(calendar_id:, event_title:, start_time:, end_time:, description: '', participants: [])
    @calendar_id = calendar_id
    @event_title = event_title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @participants = participants
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = APPLICATION_NAME
    authorize
  end

  def call
    event = create_event
    begin
      result = @service.insert_event(@calendar_id, event)
      Sublayer.configuration.logger.log(:info, "Event created: #{result.html_link}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Google API error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
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
      puts "Open the following URL in the browser and enter the resulting code after authorization:\n" + url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    @service.authorization = credentials
  end

  def create_event
    Google::Apis::CalendarV3::Event.new(
      summary: @event_title,
      location: 'Online',
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @start_time.rfc3339,
        time_zone: 'America/Los_Angeles'
      ),
      end: Google::Apis::CalendarV3::EventDateTime.new(
        date_time: @end_time.rfc3339,
        time_zone: 'America/Los_Angeles'
      ),
      attendees: @participants.map { |email| { email: email } },
      reminders: {
        use_default: false,
        overrides: [
          { method: 'email', minutes: 24 * 60 },
          { method: 'popup', minutes: 10 },
        ],
      },
    )
  end
end
