require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action integrates with the Google Calendar API to create calendar events programmatically.
#
# Requires: google-api-client gem
# $ gem install google-api-client
# Or add `gem 'google-api-client'` to your Gemfile
#
# Authentication:
# Requires a Google Cloud service account credentials JSON file path in GOOGLE_CALENDAR_CREDENTIALS env var
# The service account needs to have access to the calendar being modified
#
# It is initialized with event details including title, start_time, end_time, and optional parameters.
# Returns the created event's ID on success.
#
# Example usage: When you want to automatically schedule meetings, create follow-ups,
# or manage calendar events based on AI-driven processes.

class GoogleCalendarEventCreateAction < Sublayer::Actions::Base
  def initialize(
    calendar_id:,
    title:,
    start_time:,
    end_time:,
    description: nil,
    location: nil,
    attendees: []
  )
    @calendar_id = calendar_id
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @location = location
    @attendees = attendees
    setup_client
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(
        :info,
        "Successfully created calendar event: #{result.id}"
      )
      
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_client
    @service = Google::Apis::CalendarV3::CalendarService.new
    credentials = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: Google::Apis::CalendarV3::AUTH_CALENDAR
    )
    @service.authorization = credentials
  end

  def create_event_object
    Google::Apis::CalendarV3::Event.new(
      summary: @title,
      location: @location,
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
  end
end
