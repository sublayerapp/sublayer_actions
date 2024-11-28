# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action is intended to automate scheduling tasks by creating events directly in Google Calendar.
#
# It is initialized with details such as title, description, start_time, end_time, attendees, and reminders.
# The action returns the event ID for verification after successful creation.
#
# Example usage: Automatically create calendar events for deadlines or scheduled meetings from AI-generated insights.

require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'
  APPLICATION_NAME = 'Sublayer Google Calendar API'
  CREDENTIALS_PATH = 'path/to/credentials.json'
  TOKEN_PATH = 'token.yaml'
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], reminders: [])
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @reminders = reminders
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: Google::Apis::CalendarV3::EventDateTime.new(date_time: @start_time),
      end: Google::Apis::CalendarV3::EventDateTime.new(date_time: @end_time),
      attendees: @attendees.map { |email| { email: email } },
      reminders: Google::Apis::CalendarV3::Event::Reminders.new(
        use_default: false,
        overrides: @reminders
      )
    )

    result = @service.insert_event('primary', event)
    Sublayer.configuration.logger.log(:info, "Event created successfully: #{result.id}")
    result.id
  rescue Google::Apis::Error => e
    error_message = "Error creating Google Calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
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
      puts "Open the following URL in the browser and enter the resulting code after authorization: 
", url
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end
end
