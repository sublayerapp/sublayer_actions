require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for programmatic creation of calendar events with specified details
# such as title, description, start/end times, and attendees.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# Authentication requires a Google Cloud project and OAuth2 credentials:
# 1. Set up a Google Cloud project
# 2. Enable the Google Calendar API
# 3. Create OAuth 2.0 credentials
# 4. Store the credentials JSON in a secure location
#
# Environment variables needed:
# - GOOGLE_CALENDAR_CREDENTIALS: Path to OAuth2 credentials JSON file
#
# Example usage: When you want an AI agent to schedule meetings or create calendar
# entries based on analysis or generated content.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], calendar_id: 'primary')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @description = description
    @attendees = attendees
    @calendar_id = calendar_id
    setup_client
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Successfully created calendar event: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def setup_client
    @service = Google::Apis::CalendarV3::CalendarService.new
    credentials = Google::Auth::ServiceAccountCredentials.from_env(
      'GOOGLE_CALENDAR_CREDENTIALS'
    )
    @service.authorization = credentials
  end

  def create_event_object
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
      }
    )

    unless @attendees.empty?
      event.attendees = @attendees.map do |email|
        Google::Apis::CalendarV3::EventAttendee.new(email: email)
      end
    end

    event
  end
end