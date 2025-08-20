require 'google/apis/calendar_v3'
require 'googleauth'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for easy integration with Google Calendar, enabling AI agents
# to schedule meetings or create reminders based on generated insights.
#
# Requires: 'google-apis-calendar_v3' and 'googleauth' gems
# $ gem install google-apis-calendar_v3 googleauth
# Or add to your Gemfile:
# gem 'google-apis-calendar_v3'
# gem 'googleauth'
#
# It is initialized with event details including title, start_time, duration (in minutes),
# and optional parameters like description, attendees, and calendar_id.
# It returns the ID of the created event.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar
# reminders based on conversation analysis or task processing.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, duration_minutes:, description: nil, attendees: [], calendar_id: 'primary')
    @title = title
    @start_time = start_time
    @duration_minutes = duration_minutes
    @description = description
    @attendees = attendees
    @calendar_id = calendar_id
    @service = initialize_service
  end

  def call
    begin
      event = create_event_object
      result = @service.insert_event(@calendar_id, event)
      
      Sublayer.configuration.logger.log(:info, "Created Google Calendar event: #{result.id}")
      result.id
    rescue Google::Apis::Error => e
      error_message = "Error creating Google Calendar event: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
  end

  private

  def initialize_service
    service = Google::Apis::CalendarV3::CalendarService.new
    service.authorization = Google::Auth::ServiceAccountCredentials.make_creds(
      json_key_io: File.open(ENV['GOOGLE_CALENDAR_CREDENTIALS']),
      scope: 'https://www.googleapis.com/auth/calendar'
    )
    service
  end

  def create_event_object
    end_time = @start_time + (@duration_minutes * 60)
    
    event = Google::Apis::CalendarV3::Event.new(
      summary: @title,
      description: @description,
      start: {
        date_time: @start_time.iso8601,
        time_zone: Time.zone.name
      },
      end: {
        date_time: end_time.iso8601,
        time_zone: Time.zone.name
      }
    )

    if @attendees.any?
      event.attendees = @attendees.map { |email| { email: email } }
    end

    event
  end
end
