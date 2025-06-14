require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for easy integration with Google Calendar, enabling AI agents
# to schedule meetings and create calendar events programmatically.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, start_time, end_time,
# and optional parameters like attendees, description, and timezone.
# It returns the created event object from Google Calendar.
#
# Example usage: When you want an AI agent to schedule meetings or create
# calendar events based on conversation context or task requirements.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, attendees: [], description: nil, timezone: 'UTC')
    @title = title
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @description = description
    @timezone = timezone
    @calendar_id = 'primary' # Uses the authenticated user's primary calendar

    initialize_client
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Calendar event created successfully: #{result.html_link}")
      result
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_client
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: 'https://www.googleapis.com/auth/calendar'
    )
  end

  def create_event_object
    Google::Apis::CalendarV3::Event.new(
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