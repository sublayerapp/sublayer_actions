require 'google/apis/calendar_v3'
require 'google/api_client/client_secrets'

# Description: Sublayer::Action responsible for creating events in Google Calendar.
# This action allows for programmatic creation of calendar events with specified details.
#
# Requires: 'google-apis-calendar_v3' gem
# $ gem install google-apis-calendar_v3
# Or add `gem 'google-apis-calendar_v3'` to your Gemfile
#
# Required environment variables:
# - GOOGLE_CALENDAR_CREDENTIALS: Path to Google Calendar API credentials JSON file
#
# It is initialized with event details including title, description, start/end times, and optional attendees.
# It returns the ID of the created calendar event.
#
# Example usage: When you want an AI agent to schedule meetings or create calendar events
# based on analyzed content or generated recommendations.

class GoogleCalendarCreateEventAction < Sublayer::Actions::Base
  def initialize(title:, start_time:, end_time:, description: nil, attendees: [], timezone: 'UTC', calendar_id: 'primary')
    @title = title
    @description = description
    @start_time = start_time
    @end_time = end_time
    @attendees = attendees
    @timezone = timezone
    @calendar_id = calendar_id
    @service = initialize_service
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
    end
  end

  private

  def initialize_service
    service = Google::Apis::CalendarV3::CalendarService.new
    
    begin
      credentials = Google::APIClient::ClientSecrets.load(ENV['GOOGLE_CALENDAR_CREDENTIALS'])
      service.authorization = credentials.to_authorization
      service
    rescue StandardError => e
      error_message = "Error initializing Google Calendar service: #{e.message}"
      Sublayer.configuration.logger.log(:error, error_message)
      raise StandardError, error_message
    end
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