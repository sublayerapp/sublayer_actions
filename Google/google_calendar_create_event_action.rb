require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action enables AI agents to schedule meetings or create calendar events programmatically.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, start_time, duration (in minutes),
# and optional parameters like description, attendees, and location.
# It returns the ID of the created calendar event.
#
# Example usage: When you want an AI agent to schedule meetings or create reminders
# based on conversation analysis or task requirements.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, duration_minutes:, description: nil, attendees: [], location: nil)
    @title = title
    @start_time = start_time
    @duration_minutes = duration_minutes
    @description = description
    @attendees = attendees
    @location = location
    @calendar_id = 'primary' # Uses the authenticated user's primary calendar

    # Initialize the Google Calendar API client
    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.from_env(
      scope: 'https://www.googleapis.com/auth/calendar'
    )
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Calendar event created successfully with ID: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    rescue StandardError => e
      error_message = "Unexpected error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_event_object
    # Calculate end time based on duration
    end_time = @start_time + (@duration_minutes * 60)

    # Create the event object
    Google::Apis::CalendarV3::Event.new(
      summary: @title,
      location: @location,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: Time.zone.name
      },
      end: {
        date_time: end_time.iso8601,
        time_zone: Time.zone.name
      },
      attendees: @attendees.map { |email| { email: email } },
      reminders: {
        use_default: true
      }
    )
  end
end