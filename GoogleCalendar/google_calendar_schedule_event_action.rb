require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action responsible for scheduling a new event in Google Calendar.
# This action allows for integration with Google's Calendar API to automatically create events.
# It can be used to translate AI-generated schedules into actual calendar events
# or integrate calendar scheduling into automated workflows.
#
# Requires: 'google-apis-calendar_v3' gem
# $ gem install google-apis-calendar_v3
# Or add `gem 'google-apis-calendar_v3'` to your Gemfile
#
# The action is initialized with calendar_id, summary, start_time, end_time,
# and optional description and attendees.
# It returns the event ID of the created Google Calendar event.
#
# Example usage: When you want to create a scheduled event in Google Calendar
# as part of an AI-driven process.

class GoogleCalendarScheduleEventAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Sublayer Google Calendar API'.freeze
  CREDENTIALS_PATH = 'credentials.json'.freeze
  TOKEN_PATH = 'token.yaml'.freeze
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize(calendar_id:, summary:, start_time:, end_time:, description: nil, attendees: [])
    @calendar_id = calendar_id
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
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
      ),
      attendees: @attendees.map { |email| { email: email } }
    )

    result = @service.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Google Calendar event created successfully: #{result.id}")
    result.id
  rescue Google::Apis::Error => e
    handle_error(e)
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
    credentials
  end

  def handle_error(error)
    error_message = "Error creating Google Calendar event: #{error.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  end
end
