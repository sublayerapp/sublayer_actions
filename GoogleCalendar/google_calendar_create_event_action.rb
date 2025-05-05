require 'google/apis/calendar_v3'
require 'google/api_client/client_secrets'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for programmatic creation of calendar events, which is useful
# for AI agents that need to schedule meetings or create calendar events based on
# analyzed content or communications.
#
# Requires: 'google-apis-calendar_v3' gem
# $ gem install google-apis-calendar_v3
# Or add `gem 'google-apis-calendar_v3'` to your Gemfile
#
# Required environment variables:
# - GOOGLE_CALENDAR_CREDENTIALS: Path to the Google Calendar API credentials JSON file
#
# It is initialized with start_time, end_time, title, and optional description and attendees.
# It returns the created event object from Google Calendar API.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar
# events based on analyzed content or communications.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(start_time:, end_time:, title:, description: nil, attendees: [])
    @start_time = start_time
    @end_time = end_time
    @title = title
    @description = description
    @attendees = attendees
    @calendar_id = 'primary' # Uses the authenticated user's primary calendar

    initialize_calendar_service
  end

  def call
    begin
      create_calendar_event
    rescue Google::Apis::AuthorizationError => e
      error_message = "Authorization error with Google Calendar API: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ServerError => e
      error_message = "Google Calendar API server error: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ClientError => e
      error_message = "Invalid request to Google Calendar API: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def initialize_calendar_service
    @service = Google::Apis::CalendarV3::CalendarService.new
    credentials = Google::APIClient::ClientSecrets.load(ENV['GOOGLE_CALENDAR_CREDENTIALS'])
    @service.authorization = credentials.to_authorization
    @service.authorization.fetch_access_token!
  end

  def create_calendar_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: Time.zone.name
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: Time.zone.name
      },
      attendees: @attendees.map { |email| { email: email } }
    )

    result = @service.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Calendar event created successfully with ID: #{result.id}")
    result
  end
end
