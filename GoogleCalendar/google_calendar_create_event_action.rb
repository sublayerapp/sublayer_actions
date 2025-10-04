require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action enables AI workflows to programmatically schedule meetings or events.
#
# Requires:
# - google-apis-calendar_v3 gem
# - googleauth gem
# Add to Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# Required environment variables:
# - GOOGLE_CALENDAR_CREDENTIALS: Path to service account JSON credentials file
#
# It is initialized with event details including title, start_time, duration_minutes,
# and optional parameters like description, attendees, and calendar_id.
# It returns the created event object.
#
# Example usage: When you want an AI workflow to schedule meetings or create calendar
# events based on natural language processing or automated triggers.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(
    title:,
    start_time:,
    duration_minutes:,
    description: nil,
    attendees: [],
    calendar_id: 'primary',
    timezone: 'UTC'
  )
    @title = title
    @start_time = start_time
    @duration_minutes = duration_minutes
    @description = description
    @attendees = attendees
    @calendar_id = calendar_id
    @timezone = timezone
    setup_client
  end

  def call
    begin
      create_calendar_event
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_client
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: 'https://www.googleapis.com/auth/calendar'
    )
  end

  def create_calendar_event
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: @timezone
      },
      end: {
        date_time: (@start_time + (@duration_minutes * 60)).iso8601,
        time_zone: @timezone
      },
      attendees: @attendees.map { |email| { email: email } }
    )

    result = @service.insert_event(@calendar_id, event, send_notifications: true)
    
    Sublayer.configuration.logger.log(
      :info,
      "Created Google Calendar event: #{result.html_link}"
    )

    result
  end
end
