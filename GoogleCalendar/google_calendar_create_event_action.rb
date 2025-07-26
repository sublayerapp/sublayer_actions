require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action integrates with the Google Calendar API to create calendar events with
# specified title, description, date/time, and attendees.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, start_time, end_time,
# and optional parameters like description and attendees.
# It returns the ID of the created calendar event.
#
# Example usage: When you want to automatically schedule meetings or create calendar
# events based on AI-generated content or automated processes.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], calendar_id: 'primary')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @calendar_id = calendar_id
    @service = initialize_calendar_service
  end

  def call
    begin
      create_calendar_event
    rescue Google::Apis::AuthorizationError => e
      error_message = "Authorization error with Google Calendar API: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ClientError => e
      error_message = "Client error with Google Calendar API: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue Google::Apis::ServerError => e
      error_message = "Server error with Google Calendar API: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_calendar_service
    service = Google::Apis::CalendarV3::CalendarService.new
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: 'https://www.googleapis.com/auth/calendar.events'
    )
    service.authorization = authorizer
    service
  end

  def create_calendar_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: 'UTC'
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: 'UTC'
      },
      attendees: @attendees.map { |email| { email: email } }
    )

    result = @service.insert_event(@calendar_id, event)
    Sublayer.configuration.logger.log(:info, "Created calendar event: #{result.id}")
    result.id
  end
end