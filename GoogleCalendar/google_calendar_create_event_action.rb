require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action allows for automated calendar event creation within AI workflows.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# Authentication:
# Requires a Google Cloud service account credentials file path in GOOGLE_CALENDAR_CREDENTIALS env var
# and the calendar ID in GOOGLE_CALENDAR_ID env var (or passed as parameter)
#
# It is initialized with event details including title, start_time, end_time, and optional
# description and attendees.
# It returns the created event object.
#
# Example usage: When you want an AI agent to schedule follow-up meetings or create
# reminders based on conversation analysis or task completion.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(
    title:,
    start_time:,
    end_time:,
    description: nil,
    attendees: [],
    calendar_id: nil,
    timezone: 'UTC'
  )
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @calendar_id = calendar_id || ENV['GOOGLE_CALENDAR_ID']
    @timezone = timezone
    @service = initialize_service
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

  def initialize_service
    service = Google::Apis::CalendarV3::CalendarService.new
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
    service.authorization = credentials
    service
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
        date_time: @end_time.iso8601,
        time_zone: @timezone
      },
      attendees: @attendees.map { |email| { email: email } }
    )

    result = @service.insert_event(
      @calendar_id,
      event,
      send_notifications: true
    )

    Sublayer.configuration.logger.log(
      :info,
      "Successfully created calendar event: #{result.html_link}"
    )

    result
  end
end