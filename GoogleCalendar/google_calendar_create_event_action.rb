require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action enables AI agents to schedule meetings or tasks programmatically.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including start_time, end_time, title,
# description, and optionally attendees.
# It returns the ID of the created calendar event.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar
# events based on generated content or analysis.
#
# Note: Requires a Google Cloud project and OAuth2 credentials set up with Calendar API access.
# The credentials.json file path should be set in GOOGLE_CALENDAR_CREDENTIALS env variable.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(start_time:, end_time:, title:, description: nil, attendees: [], calendar_id: 'primary')
    @start_time = start_time
    @end_time = end_time
    @title = title
    @description = description
    @attendees = attendees
    @calendar_id = calendar_id
    @service = initialize_calendar_service
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Created calendar event: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_calendar_service
    calendar = Google::Apis::CalendarV3::CalendarService.new
    authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
    calendar.authorization = authorizer
    calendar
  end

  def create_event_object
    Google::Apis::CalendarV3::Event.new(
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
      attendees: format_attendees,
      reminders: {
        use_default: true
      }
    )
  end

  def format_attendees
    @attendees.map { |email| { email: email } }
  end
end