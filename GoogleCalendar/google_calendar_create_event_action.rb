require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

require 'fileutils'

OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
CREDENTIALS_PATH = 'token.yaml'.freeze

# Description: Sublayer::Action responsible for creating an event in a Google Calendar.
# This action integrates with the Google Calendar API to create events.
#
# It is initialized with calendar_id, event_title, start_time, end_time, description, and attendees.
# It returns the event id of the created event.
#
# Example usage: When you want to automatically create calendar events based on AI-generated schedules or reminders.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(calendar_id:, event_title:, start_time:, end_time:, description: nil, attendees: [])
    @calendar_id = calendar_id
    @event_title = event_title
    @start_time = start_time # Should be an ISO 8601 timestamp string
    @end_time = end_time     # Should be an ISO 8601 timestamp string
    @description = description
    @attendees = attendees   # Array of email addresses
  end

  def call
    event = create_event
    event.id
  rescue Google::Apis::Error => e
    error_message = "Error creating Google Calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end

  private

  ##
  # Ensure valid credentials, either by fetching from the save file
  # or intitiating an OAuth2 authorization request.
  def authorize
    client_id = Google::Auth::ClientId.from_file(ENV['GOOGLE_CLIENT_SECRET_PATH'])
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

  def create_event
    service = Google::Apis::CalendarV3::CalendarService.new
    service.client_options.application_name = 'Sublayer Action'
    service.authorization = authorize

    event = Google::Apis::CalendarV3::Event.new(
      summary: @event_title,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time),
      attendees: @attendees.map { |email| { email: email } }
    )

    result = service.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Event created successfully in Google Calendar with ID: #{result.id}")
    result
  end
end
