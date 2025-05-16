require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action integrates with Google Calendar API to schedule meetings or create reminders.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, start_time, duration_minutes, and optional attendees.
# It returns the created event's ID on success.
#
# Example usage: When an AI agent needs to schedule a meeting or create a reminder based on
# conversation analysis or task requirements.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, duration_minutes:, attendees: [], description: nil, location: nil)
    @title = title
    @start_time = start_time
    @duration_minutes = duration_minutes
    @attendees = attendees
    @description = description
    @location = location
    @calendar_id = 'primary' # Uses the authenticated user's primary calendar

    @service = Google::Apis::CalendarV3::CalendarService.new
    @service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: 'https://www.googleapis.com/auth/calendar'
    )
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
    rescue StandardError => e
      error_message = "Unexpected error creating calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise e
    end
  end

  private

  def create_event_object
    end_time = @start_time + (@duration_minutes * 60)
    
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
