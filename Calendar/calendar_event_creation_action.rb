require 'google/apis/calendar_v3'
require 'googleauth'
require 'googleauth/stores/file_token_store'
require 'fileutils'

# Description: Sublayer::Action for creating calendar events in Google Calendar.
# This action is useful for automating the scheduling of events based on AI-driven insights.
#
# It is initialized with a title, start_time, end_time, attendees (email addresses), and optional description and location.
# It returns the ID of the created calendar event.
#
# Example usage: When you have an AI process that suggests meetings or events, you can use this action to automatically schedule them.

class CalendarEventCreationAction < Sublayer::Actions::Base
  OOB_URI = 'urn:ietf:wg:oauth:2.0:oob'.freeze
  APPLICATION_NAME = 'Google Calendar API Ruby Quickstart'.freeze
  CREDENTIALS_PATH = 'credentials.json'.freeze
  TOKEN_PATH = 'token.yaml'.freeze
  SCOPE = Google::Apis::CalendarV3::AUTH_CALENDAR

  def initialize(title:, start_time:, end_time:, attendees: [], description: nil, location: nil)
    @title = title
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @description = description
    @location = location

    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.client_options.application_name = APPLICATION_NAME
    @service.authorization = authorize
  end

  def call
    begin
      event = Google::Apis::CalendarV3::Event.new(
        summary: @title,
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
        attendees: @attendees.map { |email| { email: email } },
        reminders: {
          use_default: false,
          overrides: [
            { method: 'email', minutes: 24 * 60 },
            { method: 'popup', minutes: 10 },
          ],
        },
      )

      result = @service.insert_event('primary', event)
      Sublayer.configuration.logger.log(:info, "Event created: ", result.id)
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
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
      puts "Open the following URL in the browser and enter the resulting code after authorization: 
      "#{url}"
      code = gets
      credentials = authorizer.get_and_store_credentials_from_code(
        user_id: user_id, code: code, base_url: OOB_URI
      )
    end
    credentials
  end
end
