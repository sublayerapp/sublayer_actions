require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action integrates with Google Calendar using the API Client and Service Account for authentication.
#
# It is initialized with parameters for event details such as summary, start_time, end_time, description, location, and attendees.
# It returns the event ID of the created Google Calendar event.
#
# Example usage: When you want to schedule an event in Google Calendar based on AI-generated suggestions or user inputs.

class GoogleCalendarEventCreateAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Google Calendar API Ruby Quickstart'.freeze
  CREDENTIALS_PATH = 'path/to/credentials.json'.freeze
  TOKEN_PATH = 'token.yaml'.freeze
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize(summary:, start_time:, end_time:, description: '', location: '', attendees: [])
    @summary = summary
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location
    @attendees = attendees
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
    create_event
  rescue Google::Apis::ClientError => e
    error_message = "Google API Client error during event creation: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise StandardError, error_message
  rescue StandardError => e
    error_message = "Error creating Google Calendar event: #{e.message}"
    Sublayer.configuration.logger.log(:error, error_message)
    raise e
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
      puts "Open the following URL in the browser and enter the resulting code after authorization: #{url}"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(user_id: user_id, code: code, base_url: OOB_URI)
    end
    credentials
  end

  def create_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @summary,
      location: @location,
      description: @description,
      start: {
        date_time: @start_time,
        time_zone: 'America/Los_Angeles',
      },
      end: {
        date_time: @end_time,
        time_zone: 'America/Los_Angeles',
      },
      attendees: @attendees.map { |email| {email: email} }
    )

    event = @service.insert_event('primary', event)
    Sublayer.configuration.logger.log(:info, "Event successfully created in Google Calendar with ID: #{event.id}")
    event.id
  end
end
