require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating an event in Google Calendar.
# This action allows AI agents to programmatically schedule meetings or events.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, description, start_time, end_time, and optional attendees.
# It returns the ID of the created calendar event.
#
# Example usage: When an AI agent needs to schedule a meeting based on a conversation or
# create calendar events based on generated content.

class GoogleCalendarScheduleEventAction < Sublayer::Actions::Base
  def initialize(title:, description:, start_time:, end_time:, attendees: [], time_zone: 'UTC')
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @time_zone = time_zone
    @calendar_id = 'primary' # Uses the primary calendar of the authenticated user
    
    setup_client
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Calendar event created successfully with ID: #{result.id}")
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
    # Expects GOOGLE_CALENDAR_CREDENTIALS to contain the path to the service account JSON key file
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
        time_zone: @time_zone
      },
      end: {
        date_time: @end_time.iso8601,
        time_zone: @time_zone
      },
      attendees: @attendees.map { |email| { email: email } },
      reminders: {
        use_default: true
      }
    )
  end
end