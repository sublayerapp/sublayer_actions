require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows easy integration with Google Calendar for scheduling meetings and events
# from AI-driven processes.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, description, start/end times, and attendees.
# It returns the created event's ID on success.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar events
# based on conversation context or generated content.

class GoogleCalendarEventCreateAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], timezone: 'UTC')
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @timezone = timezone
    @calendar_id = 'primary' # Uses the authenticated user's primary calendar

    initialize_client
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

  def initialize_client
    @service = Google::Apis::CalendarV3::CalendarService.new
    
    # Expects credentials to be set up via environment variable GOOGLE_APPLICATION_CREDENTIALS
    # pointing to a service account JSON key file with Calendar API access
    @service.authorization = Google::Auth.get_application_default(
      [Google::Apis::CalendarV3::AUTH_CALENDAR]
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
      attendees: @attendees.map { |email| { email: email } },
      reminders: {
        use_default: true
      }
    )
  end
end