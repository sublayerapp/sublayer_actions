require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action integrates with Google Calendar API to create calendar events with specified details.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, description, start_time, end_time,
# and optional attendees list. Returns the created event's ID.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar events
# based on conversation context or generated content.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, description:, start_time:, end_time:, attendees: [])
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @calendar_id = 'primary' # Uses the authenticated user's primary calendar

    initialize_client
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
        time_zone: 'UTC'
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: 'UTC'
      },
      attendees: @attendees.map { |email| { email: email } },
      reminders: {
        use_default: true
      }
    )
  end
end